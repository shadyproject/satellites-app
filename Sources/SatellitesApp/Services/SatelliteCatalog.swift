import Foundation
import SwiftData
import SatellitesKit

/// Manages the satellite catalog using SwiftData.
@MainActor
final class SatelliteCatalog {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    // MARK: - CRUD Operations

    /// Fetches all satellites from the catalog.
    func fetchAll() throws -> [SatelliteModel] {
        let descriptor = FetchDescriptor<SatelliteModel>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches a satellite by NORAD ID.
    func fetch(noradID: Int) throws -> SatelliteModel? {
        let descriptor = FetchDescriptor<SatelliteModel>(
            predicate: #Predicate { $0.noradID == noradID }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Adds a new satellite to the catalog.
    func add(_ satellite: TrackedSatellite, isUserAdded: Bool = true) throws {
        let model = satellite.toModel(isUserAdded: isUserAdded)
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Updates an existing satellite's TLE data.
    func updateTLE(noradID: Int, tleLine0: String, tleLine1: String, tleLine2: String) throws {
        guard let satellite = try fetch(noradID: noradID) else { return }
        satellite.tleLine0 = tleLine0
        satellite.tleLine1 = tleLine1
        satellite.tleLine2 = tleLine2
        satellite.tleUpdatedAt = Date()
        try modelContext.save()
    }

    /// Deletes a satellite from the catalog.
    func delete(noradID: Int) throws {
        guard let satellite = try fetch(noradID: noradID) else { return }
        modelContext.delete(satellite)
        try modelContext.save()
    }

    /// Deletes all user-added satellites.
    func deleteAllUserAdded() throws {
        let descriptor = FetchDescriptor<SatelliteModel>(
            predicate: #Predicate { $0.isUserAdded == true }
        )
        let satellites = try modelContext.fetch(descriptor)
        for satellite in satellites {
            modelContext.delete(satellite)
        }
        try modelContext.save()
    }

    // MARK: - Seeding

    /// Seeds the catalog with default satellites if empty.
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<SatelliteModel>()
        let count = try modelContext.fetchCount(descriptor)

        if count == 0 {
            try seedDefaults()
        } else {
            // Assign random colors to satellites migrated with default color
            try assignMissingColors()
        }
    }

    /// Assigns random colors to satellites that have the default migration color.
    private func assignMissingColors() throws {
        let defaultColor = "3B82F6"
        let satellites = try fetchAll()
        var needsSave = false

        for satellite in satellites where satellite.colorHex == defaultColor {
            satellite.colorHex = SatelliteModel.generateRandomColorHex()
            needsSave = true
        }

        if needsSave {
            try modelContext.save()
        }
    }

    /// Seeds the catalog with default satellites.
    func seedDefaults() throws {
        for satellite in Self.defaultSatellites {
            let model = satellite.toModel(isUserAdded: false)
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    /// Resets catalog to default satellites only.
    func resetToDefaults() throws {
        // Delete all satellites
        let descriptor = FetchDescriptor<SatelliteModel>()
        let satellites = try modelContext.fetch(descriptor)
        for satellite in satellites {
            modelContext.delete(satellite)
        }

        // Re-seed with defaults
        try seedDefaults()
    }

    // MARK: - Default Satellites

    static let defaultSatellites: [TrackedSatellite] = [
        TrackedSatellite(
            name: "USA-247 (NROL-39)",
            noradID: 39462,
            tle: TLE(
                line0: "USA 247 (NROL-39)",
                line1: "1 39462U 13072A   26041.16551075  .00000000  00000-0  00000-0 0    03",
                line2: "2 39462 122.9989 351.0180 0003790 117.2045 242.8260 13.41447760    04"
            )
        ),
        TrackedSatellite(
            name: "ISS (ZARYA)",
            noradID: 25544,
            tle: TLE(
                line0: "ISS (ZARYA)",
                line1: "1 25544U 98067A   24056.54791667  .00016717  00000-0  30000-3 0  9993",
                line2: "2 25544  51.6400 247.4627 0006703  55.0000 305.1234 15.49815432440000"
            )
        ),
        TrackedSatellite(
            name: "Hubble Space Telescope",
            noradID: 20580,
            tle: TLE(
                line0: "HST",
                line1: "1 20580U 90037B   24056.50000000  .00001200  00000-0  60000-4 0  9990",
                line2: "2 20580  28.4700 120.0000 0002500  90.0000 270.0000 15.09000000400000"
            )
        ),
        TrackedSatellite(
            name: "NOAA-19",
            noradID: 33591,
            tle: TLE(
                line0: "NOAA 19",
                line1: "1 33591U 09005A   24056.50000000  .00000100  00000-0  80000-4 0  9990",
                line2: "2 33591  99.1900  60.0000 0014000  90.0000 270.0000 14.12500000700000"
            )
        ),
        TrackedSatellite(
            name: "Terra (EOS AM-1)",
            noradID: 25994,
            tle: TLE(
                line0: "TERRA",
                line1: "1 25994U 99068A   24056.50000000  .00000100  00000-0  50000-4 0  9990",
                line2: "2 25994  98.2100  90.0000 0001200 100.0000 260.0000 14.57100000100000"
            )
        ),
        TrackedSatellite(
            name: "Landsat 9",
            noradID: 49260,
            tle: TLE(
                line0: "LANDSAT 9",
                line1: "1 49260U 21088A   24056.50000000  .00000100  00000-0  40000-4 0  9990",
                line2: "2 49260  98.2200  45.0000 0001500  85.0000 275.0000 14.57200000100000"
            )
        ),
        TrackedSatellite(
            name: "GOES-16",
            noradID: 41866,
            tle: TLE(
                line0: "GOES 16",
                line1: "1 41866U 16071A   24056.50000000  .00000010  00000-0  00000-0 0  9990",
                line2: "2 41866   0.0400 270.0000 0001000  90.0000 270.0000  1.00270000500000"
            )
        ),
        TrackedSatellite(
            name: "Starlink-1007",
            noradID: 44713,
            tle: TLE(
                line0: "STARLINK-1007",
                line1: "1 44713U 19074A   24056.50000000  .00010000  00000-0  70000-3 0  9990",
                line2: "2 44713  53.0000 200.0000 0001500  80.0000 280.0000 15.06000000200000"
            )
        ),
    ]
}
