import Foundation

/// Coordinate transformation utilities for satellite tracking.
public enum CoordinateTransform {
    /// Converts ECI (Earth-Centered Inertial) coordinates to geodetic (lat/lon/alt).
    ///
    /// - Parameters:
    ///   - eci: Position in ECI coordinates (km)
    ///   - date: Time of the position for GMST calculation
    /// - Returns: Geodetic position (lat/lon in degrees, alt in km)
    public static func eciToGeodetic(_ eci: ECIPosition, at date: Date) -> GeodeticPosition {
        let gmst = greenwichMeanSiderealTime(date)

        // Convert ECI to ECEF by rotating by GMST
        let cosGmst = cos(gmst)
        let sinGmst = sin(gmst)

        let xEcef = eci.x * cosGmst + eci.y * sinGmst
        let yEcef = -eci.x * sinGmst + eci.y * cosGmst
        let zEcef = eci.z

        // Convert ECEF to geodetic using iterative method
        let a = OrbitalConstants.earthRadiusKm
        let e2 = OrbitalConstants.earthEccentricitySquared

        let p = sqrt(xEcef * xEcef + yEcef * yEcef)
        var latitude = atan2(zEcef, p * (1 - e2))

        // Iterate to converge on latitude
        for _ in 0..<10 {
            let sinLat = sin(latitude)
            let n = a / sqrt(1 - e2 * sinLat * sinLat)
            latitude = atan2(zEcef + e2 * n * sinLat, p)
        }

        let sinLat = sin(latitude)
        let n = a / sqrt(1 - e2 * sinLat * sinLat)
        let altitude = p / cos(latitude) - n

        var longitude = atan2(yEcef, xEcef)

        // Normalize longitude to -180 to 180
        while longitude > .pi {
            longitude -= OrbitalConstants.twoPi
        }
        while longitude < -.pi {
            longitude += OrbitalConstants.twoPi
        }

        return GeodeticPosition(
            latitude: latitude * OrbitalConstants.rad2deg,
            longitude: longitude * OrbitalConstants.rad2deg,
            altitude: altitude,
            date: date
        )
    }

    /// Calculates topocentric position (azimuth, elevation, range) from observer to satellite.
    ///
    /// - Parameters:
    ///   - satelliteECI: Satellite position in ECI coordinates
    ///   - observer: Ground station location
    ///   - date: Time of observation
    /// - Returns: Topocentric position relative to observer
    public static func eciToTopocentric(
        _ satelliteECI: ECIPosition,
        observer: GroundStation,
        at date: Date
    ) -> TopocentricPosition {
        let gmst = greenwichMeanSiderealTime(date)

        // Observer geodetic to ECI
        let obsLat = observer.latitude * OrbitalConstants.deg2rad
        let obsLon = observer.longitude * OrbitalConstants.deg2rad
        let obsAlt = observer.altitudeMeters / 1000.0 // Convert to km

        let a = OrbitalConstants.earthRadiusKm
        let e2 = OrbitalConstants.earthEccentricitySquared
        let sinLat = sin(obsLat)
        let cosLat = cos(obsLat)
        let n = a / sqrt(1 - e2 * sinLat * sinLat)

        // Observer ECEF position
        let obsXEcef = (n + obsAlt) * cosLat * cos(obsLon)
        let obsYEcef = (n + obsAlt) * cosLat * sin(obsLon)
        let obsZEcef = (n * (1 - e2) + obsAlt) * sinLat

        // Rotate observer ECEF to ECI
        let obsXEci = obsXEcef * cos(gmst) - obsYEcef * sin(gmst)
        let obsYEci = obsXEcef * sin(gmst) + obsYEcef * cos(gmst)
        let obsZEci = obsZEcef

        // Range vector in ECI
        let rangeX = satelliteECI.x - obsXEci
        let rangeY = satelliteECI.y - obsYEci
        let rangeZ = satelliteECI.z - obsZEci

        let range = sqrt(rangeX * rangeX + rangeY * rangeY + rangeZ * rangeZ)

        // Rotate range to topocentric (SEZ: South-East-Zenith)
        let sinLatObs = sin(obsLat)
        let cosLatObs = cos(obsLat)

        // Range in ECEF
        let rangeXEcef = rangeX * cos(gmst) + rangeY * sin(gmst)
        let rangeYEcef = -rangeX * sin(gmst) + rangeY * cos(gmst)
        let rangeZEcef = rangeZ

        // Rotate to local horizon (SEZ)
        let cosLon = cos(obsLon)
        let sinLon = sin(obsLon)

        let south = sinLatObs * cosLon * rangeXEcef +
                    sinLatObs * sinLon * rangeYEcef -
                    cosLatObs * rangeZEcef
        let east = -sinLon * rangeXEcef + cosLon * rangeYEcef
        let zenith = cosLatObs * cosLon * rangeXEcef +
                     cosLatObs * sinLon * rangeYEcef +
                     sinLatObs * rangeZEcef

        // Calculate azimuth and elevation
        var azimuth = atan2(east, -south)
        if azimuth < 0 {
            azimuth += OrbitalConstants.twoPi
        }

        let elevation = asin(zenith / range)

        return TopocentricPosition(
            azimuth: azimuth * OrbitalConstants.rad2deg,
            elevation: elevation * OrbitalConstants.rad2deg,
            range: range,
            rangeRate: 0, // Would need velocity for this
            date: date
        )
    }

    /// Calculates Greenwich Mean Sidereal Time in radians.
    ///
    /// - Parameter date: Date/time for GMST calculation
    /// - Returns: GMST in radians
    public static func greenwichMeanSiderealTime(_ date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(
            in: TimeZone(identifier: "UTC")!,
            from: date
        )

        let year = Double(components.year ?? 2000)
        let month = Double(components.month ?? 1)
        let day = Double(components.day ?? 1)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)

        // Julian date calculation
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)

        let jd = floor(365.25 * (y + 4716)) +
                 floor(30.6001 * (m + 1)) +
                 day + b - 1524.5

        let ut = hour + minute / 60.0 + second / 3600.0

        // Julian centuries from J2000.0
        let t0 = (jd - 2451545.0) / 36525.0
        let t = t0 + ut / 24.0 / 36525.0

        // GMST in degrees
        var gmstDeg = 280.46061837 +
                      360.98564736629 * (jd - 2451545.0 + ut / 24.0) +
                      0.000387933 * t * t -
                      t * t * t / 38710000.0

        // Normalize to 0-360
        gmstDeg = gmstDeg.truncatingRemainder(dividingBy: 360.0)
        if gmstDeg < 0 {
            gmstDeg += 360.0
        }

        return gmstDeg * OrbitalConstants.deg2rad
    }
}
