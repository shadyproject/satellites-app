import Foundation
import SwiftData
import SwiftUI

/// SwiftData model for persisted satellite data.
@Model
final class SatelliteModel {
    /// Unique identifier (NORAD catalog number)
    @Attribute(.unique) var noradID: Int

    /// Display name
    var name: String

    /// TLE Line 0 (name line)
    var tleLine0: String

    /// TLE Line 1
    var tleLine1: String

    /// TLE Line 2
    var tleLine2: String

    /// Date the TLE was last updated
    var tleUpdatedAt: Date

    /// Date this satellite was added to the catalog
    var createdAt: Date

    /// Whether this is a user-added satellite (vs bundled default)
    var isUserAdded: Bool

    /// Unique color for this satellite (stored as hex string)
    var colorHex: String = "3B82F6"

    init(
        noradID: Int,
        name: String,
        tleLine0: String,
        tleLine1: String,
        tleLine2: String,
        tleUpdatedAt: Date = Date(),
        createdAt: Date = Date(),
        isUserAdded: Bool = false,
        colorHex: String? = nil
    ) {
        self.noradID = noradID
        self.name = name
        self.tleLine0 = tleLine0
        self.tleLine1 = tleLine1
        self.tleLine2 = tleLine2
        self.tleUpdatedAt = tleUpdatedAt
        self.createdAt = createdAt
        self.isUserAdded = isUserAdded
        self.colorHex = colorHex ?? Self.generateRandomColorHex()
    }

    /// Generates a random vibrant color hex string.
    static func generateRandomColorHex() -> String {
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: 0.6...0.9)
        let brightness = Double.random(in: 0.7...0.95)

        let c = brightness * saturation
        let x = c * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c

        let r, g, b: Double
        switch hue * 6 {
        case 0..<1: (r, g, b) = (c, x, 0)
        case 1..<2: (r, g, b) = (x, c, 0)
        case 2..<3: (r, g, b) = (0, c, x)
        case 3..<4: (r, g, b) = (0, x, c)
        case 4..<5: (r, g, b) = (x, 0, c)
        default:    (r, g, b) = (c, 0, x)
        }

        let red = Int((r + m) * 255)
        let green = Int((g + m) * 255)
        let blue = Int((b + m) * 255)

        return String(format: "%02X%02X%02X", red, green, blue)
    }
}

// MARK: - Color Conversion

extension SatelliteModel {
    /// Returns the satellite's color as a SwiftUI Color.
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255
        let b = Double(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Conversion to TrackedSatellite

import SatellitesKit

extension SatelliteModel {
    /// Converts to a TrackedSatellite for use with SatelliteTracker.
    func toTrackedSatellite() -> TrackedSatellite {
        TrackedSatellite(
            name: name,
            noradID: noradID,
            tle: TLE(
                line0: tleLine0,
                line1: tleLine1,
                line2: tleLine2
            )
        )
    }
}

extension TrackedSatellite {
    /// Creates a SatelliteModel from a TrackedSatellite.
    func toModel(isUserAdded: Bool = false) -> SatelliteModel {
        SatelliteModel(
            noradID: noradID,
            name: name,
            tleLine0: tle.line0,
            tleLine1: tle.line1,
            tleLine2: tle.line2,
            isUserAdded: isUserAdded
        )
    }
}
