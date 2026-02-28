import Foundation
import SatelliteKit

/// Error types for satellite tracking operations.
public enum SatelliteTrackerError: Error, Sendable {
    case invalidTLE(String)
    case propagationFailed(String)
    case dateOutOfRange
}

/// Tracks satellite position using SGP4/SDP4 propagation.
public final class SatelliteTracker: Sendable {
    private let satellite: Satellite
    private let elements: Elements
    public let trackedSatellite: TrackedSatellite

    /// Creates a tracker for the given satellite TLE.
    ///
    /// - Parameter satellite: Satellite with TLE data
    /// - Throws: `SatelliteTrackerError.invalidTLE` if TLE parsing fails
    public init(satellite: TrackedSatellite) throws {
        self.trackedSatellite = satellite

        do {
            self.elements = try Elements(
                satellite.tle.line0,
                satellite.tle.line1,
                satellite.tle.line2
            )
            self.satellite = Satellite(withTLE: self.elements)
        } catch {
            throw SatelliteTrackerError.invalidTLE(
                "Failed to parse TLE: \(error.localizedDescription)"
            )
        }
    }

    /// TLE epoch date.
    public var epochDate: Date {
        Date(timeIntervalSince1970: elements.t₀ * 60.0)
    }

    /// Calculates satellite position in ECI coordinates at the given time.
    ///
    /// - Parameter date: Time for position calculation
    /// - Returns: Position in ECI coordinates
    /// - Throws: `SatelliteTrackerError.propagationFailed` on calculation error
    public func position(at date: Date) throws -> ECIPosition {
        let minutesAfterEpoch = minutesSinceEpoch(date)

        do {
            let posVector = try satellite.position(minsAfterEpoch: minutesAfterEpoch)
            return ECIPosition(
                x: posVector.x,
                y: posVector.y,
                z: posVector.z,
                date: date
            )
        } catch {
            throw SatelliteTrackerError.propagationFailed(
                "SGP4 propagation failed: \(error.localizedDescription)"
            )
        }
    }

    /// Calculates satellite geodetic position (lat/lon/alt) at the given time.
    ///
    /// - Parameter date: Time for position calculation
    /// - Returns: Geodetic position
    public func geodeticPosition(at date: Date) throws -> GeodeticPosition {
        let eci = try position(at: date)
        return CoordinateTransform.eciToGeodetic(eci, at: date)
    }

    /// Calculates satellite position relative to an observer.
    ///
    /// - Parameters:
    ///   - date: Time for calculation
    ///   - observer: Ground station location
    /// - Returns: Topocentric position (azimuth, elevation, range)
    public func topocentricPosition(
        at date: Date,
        from observer: GroundStation
    ) throws -> TopocentricPosition {
        let eci = try position(at: date)
        return CoordinateTransform.eciToTopocentric(eci, observer: observer, at: date)
    }

    /// Generates a ground track (sub-satellite points) over a time period.
    ///
    /// - Parameters:
    ///   - start: Start time
    ///   - duration: Duration in seconds
    ///   - interval: Time between points in seconds
    /// - Returns: Array of geodetic positions forming the ground track
    public func groundTrack(
        from start: Date,
        duration: TimeInterval,
        interval: TimeInterval = 60
    ) throws -> [GeodeticPosition] {
        var positions: [GeodeticPosition] = []
        var currentTime = start

        while currentTime <= start.addingTimeInterval(duration) {
            if let position = try? geodeticPosition(at: currentTime) {
                positions.append(position)
            }
            currentTime = currentTime.addingTimeInterval(interval)
        }

        return positions
    }

    /// Orbital period in minutes.
    public var orbitalPeriodMinutes: Double {
        OrbitalConstants.twoPi / elements.n₀
    }

    /// Inclination in degrees.
    public var inclination: Double {
        elements.i₀ * OrbitalConstants.rad2deg
    }

    /// Eccentricity.
    public var eccentricity: Double {
        elements.e₀
    }

    /// Calculates minutes since TLE epoch.
    private func minutesSinceEpoch(_ date: Date) -> Double {
        let epochSeconds = elements.t₀ * 60.0
        let dateSeconds = date.timeIntervalSince1970
        return (dateSeconds - epochSeconds) / 60.0
    }
}

// MARK: - Predefined Satellites

extension TrackedSatellite {
    /// USA-247 (NROL-39) reconnaissance satellite.
    /// NORAD ID: 39462
    public static let usa247 = TrackedSatellite(
        name: "USA-247 (NROL-39)",
        noradID: 39462,
        tle: TLE(
            line0: "USA 247 (NROL-39)",
            line1: "1 39462U 13072A   26041.16551075  .00000000  00000-0  00000-0 0    03",
            line2: "2 39462 122.9989 351.0180 0003790 117.2045 242.8260 13.41447760    04"
        )
    )

    /// International Space Station.
    /// NORAD ID: 25544
    public static let iss = TrackedSatellite(
        name: "ISS (ZARYA)",
        noradID: 25544,
        tle: TLE(
            line0: "ISS (ZARYA)",
            line1: "1 25544U 98067A   24056.54791667  .00016717  00000-0  30000-3 0  9993",
            line2: "2 25544  51.6400 247.4627 0006703  55.0000 305.1234 15.49815432440000"
        )
    )

    /// Hubble Space Telescope.
    /// NORAD ID: 20580
    public static let hubble = TrackedSatellite(
        name: "Hubble Space Telescope",
        noradID: 20580,
        tle: TLE(
            line0: "HST",
            line1: "1 20580U 90037B   24056.50000000  .00001200  00000-0  60000-4 0  9990",
            line2: "2 20580  28.4700 120.0000 0002500  90.0000 270.0000 15.09000000400000"
        )
    )

    /// NOAA-19 Weather Satellite.
    /// NORAD ID: 33591
    public static let noaa19 = TrackedSatellite(
        name: "NOAA-19",
        noradID: 33591,
        tle: TLE(
            line0: "NOAA 19",
            line1: "1 33591U 09005A   24056.50000000  .00000100  00000-0  80000-4 0  9990",
            line2: "2 33591  99.1900  60.0000 0014000  90.0000 270.0000 14.12500000700000"
        )
    )

    /// Terra Earth Observation Satellite.
    /// NORAD ID: 25994
    public static let terra = TrackedSatellite(
        name: "Terra (EOS AM-1)",
        noradID: 25994,
        tle: TLE(
            line0: "TERRA",
            line1: "1 25994U 99068A   24056.50000000  .00000100  00000-0  50000-4 0  9990",
            line2: "2 25994  98.2100  90.0000 0001200 100.0000 260.0000 14.57100000100000"
        )
    )

    /// Landsat 9.
    /// NORAD ID: 49260
    public static let landsat9 = TrackedSatellite(
        name: "Landsat 9",
        noradID: 49260,
        tle: TLE(
            line0: "LANDSAT 9",
            line1: "1 49260U 21088A   24056.50000000  .00000100  00000-0  40000-4 0  9990",
            line2: "2 49260  98.2200  45.0000 0001500  85.0000 275.0000 14.57200000100000"
        )
    )

    /// GOES-16 Weather Satellite (Geostationary).
    /// NORAD ID: 41866
    public static let goes16 = TrackedSatellite(
        name: "GOES-16",
        noradID: 41866,
        tle: TLE(
            line0: "GOES 16",
            line1: "1 41866U 16071A   24056.50000000  .00000010  00000-0  00000-0 0  9990",
            line2: "2 41866   0.0400 270.0000 0001000  90.0000 270.0000  1.00270000500000"
        )
    )

    /// Starlink-1007 (example Starlink satellite).
    /// NORAD ID: 44713
    public static let starlink1007 = TrackedSatellite(
        name: "Starlink-1007",
        noradID: 44713,
        tle: TLE(
            line0: "STARLINK-1007",
            line1: "1 44713U 19074A   24056.50000000  .00010000  00000-0  70000-3 0  9990",
            line2: "2 44713  53.0000 200.0000 0001500  80.0000 280.0000 15.06000000200000"
        )
    )

    /// All available satellites for tracking.
    public static let allSatellites: [TrackedSatellite] = [
        .usa247,
        .iss,
        .hubble,
        .noaa19,
        .terra,
        .landsat9,
        .goes16,
        .starlink1007,
    ]
}
