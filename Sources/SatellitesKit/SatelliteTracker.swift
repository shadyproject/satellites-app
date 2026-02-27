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
}
