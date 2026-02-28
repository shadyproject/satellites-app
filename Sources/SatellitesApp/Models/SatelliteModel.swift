import Foundation
import SwiftData

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

    init(
        noradID: Int,
        name: String,
        tleLine0: String,
        tleLine1: String,
        tleLine2: String,
        tleUpdatedAt: Date = Date(),
        createdAt: Date = Date(),
        isUserAdded: Bool = false
    ) {
        self.noradID = noradID
        self.name = name
        self.tleLine0 = tleLine0
        self.tleLine1 = tleLine1
        self.tleLine2 = tleLine2
        self.tleUpdatedAt = tleUpdatedAt
        self.createdAt = createdAt
        self.isUserAdded = isUserAdded
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
