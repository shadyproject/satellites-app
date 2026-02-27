import Foundation

/// Physical and mathematical constants for orbital calculations.
public enum OrbitalConstants {
    /// Earth's equatorial radius in kilometers (WGS-84)
    public static let earthRadiusKm: Double = 6378.137

    /// Earth's polar radius in kilometers (WGS-84)
    public static let earthPolarRadiusKm: Double = 6356.752

    /// Earth's flattening factor (WGS-84)
    public static let earthFlattening: Double = 1.0 / 298.257223563

    /// Earth's eccentricity squared
    public static let earthEccentricitySquared: Double = 0.00669437999014

    /// Earth's rotation rate in radians per minute
    public static let earthRotationRateRadPerMin: Double = 7.29211514670698e-5 * 60.0

    /// Minutes per day
    public static let minutesPerDay: Double = 1440.0

    /// Seconds per day
    public static let secondsPerDay: Double = 86400.0

    /// Degrees to radians conversion factor
    public static let deg2rad: Double = .pi / 180.0

    /// Radians to degrees conversion factor
    public static let rad2deg: Double = 180.0 / .pi

    /// Two pi
    public static let twoPi: Double = 2.0 * .pi
}
