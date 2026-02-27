import Foundation
import SatelliteKit

/// Represents a satellite being tracked with its current state.
public struct TrackedSatellite: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let noradID: Int
    public let tle: TLE

    public init(name: String, noradID: Int, tle: TLE) {
        self.id = noradID
        self.name = name
        self.noradID = noradID
        self.tle = tle
    }
}

/// Two-Line Element data for orbit propagation.
public struct TLE: Sendable {
    public let line0: String
    public let line1: String
    public let line2: String

    public init(line0: String, line1: String, line2: String) {
        self.line0 = line0
        self.line1 = line1
        self.line2 = line2
    }
}

/// Position in Earth-Centered Inertial (ECI) coordinates.
public struct ECIPosition: Sendable {
    /// X position in kilometers
    public let x: Double
    /// Y position in kilometers
    public let y: Double
    /// Z position in kilometers
    public let z: Double
    /// Timestamp of position
    public let date: Date

    public init(x: Double, y: Double, z: Double, date: Date) {
        self.x = x
        self.y = y
        self.z = z
        self.date = date
    }

    /// Distance from Earth center in kilometers.
    public var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
}

/// Geographic coordinates with altitude.
public struct GeodeticPosition: Sendable {
    /// Latitude in degrees (-90 to 90)
    public let latitude: Double
    /// Longitude in degrees (-180 to 180)
    public let longitude: Double
    /// Altitude above sea level in kilometers
    public let altitude: Double
    /// Timestamp of position
    public let date: Date

    public init(latitude: Double, longitude: Double, altitude: Double, date: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.date = date
    }
}

/// Topocentric position relative to an observer (azimuth, elevation, range).
public struct TopocentricPosition: Sendable {
    /// Azimuth in degrees (0-360, north = 0, east = 90)
    public let azimuth: Double
    /// Elevation in degrees (-90 to 90, horizon = 0)
    public let elevation: Double
    /// Range (distance) in kilometers
    public let range: Double
    /// Range rate in km/s (positive = receding)
    public let rangeRate: Double
    /// Timestamp
    public let date: Date

    public init(azimuth: Double, elevation: Double, range: Double, rangeRate: Double, date: Date) {
        self.azimuth = azimuth
        self.elevation = elevation
        self.range = range
        self.rangeRate = rangeRate
        self.date = date
    }

    /// Whether the satellite is above the horizon.
    public var isVisible: Bool {
        elevation > 0
    }
}

/// Observer ground station location.
public struct GroundStation: Sendable {
    public let name: String
    /// Latitude in degrees
    public let latitude: Double
    /// Longitude in degrees
    public let longitude: Double
    /// Altitude in meters above sea level
    public let altitudeMeters: Double

    public init(name: String, latitude: Double, longitude: Double, altitudeMeters: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
    }

    /// Default location (San Francisco)
    public static let sanFrancisco = GroundStation(
        name: "San Francisco",
        latitude: 37.7749,
        longitude: -122.4194,
        altitudeMeters: 16
    )
}
