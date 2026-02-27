import Foundation
import SatellitesKit
import Observation

/// View model for satellite tracking.
@MainActor
@Observable
final class SatelliteViewModel {
    // MARK: - Properties

    private(set) var tracker: SatelliteTracker?
    private(set) var currentPosition: GeodeticPosition?
    private(set) var topocentricPosition: TopocentricPosition?
    private(set) var groundTrack: [GeodeticPosition] = []
    private(set) var errorMessage: String?
    private(set) var isTracking = false

    var observer: GroundStation = .sanFrancisco

    private var updateTimer: Timer?

    // MARK: - Computed Properties

    var satelliteName: String {
        tracker?.trackedSatellite.name ?? "No Satellite"
    }

    var noradID: Int {
        tracker?.trackedSatellite.noradID ?? 0
    }

    var orbitalPeriod: String {
        guard let tracker else { return "--" }
        let minutes = tracker.orbitalPeriodMinutes
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        return "\(hours)h \(mins)m"
    }

    var inclinationDegrees: String {
        guard let tracker else { return "--" }
        return String(format: "%.2f", tracker.inclination)
    }

    var altitude: String {
        guard let pos = currentPosition else { return "--" }
        return String(format: "%.1f km", pos.altitude)
    }

    var latitude: String {
        guard let pos = currentPosition else { return "--" }
        let dir = pos.latitude >= 0 ? "N" : "S"
        return String(format: "%.4f %@", abs(pos.latitude), dir)
    }

    var longitude: String {
        guard let pos = currentPosition else { return "--" }
        let dir = pos.longitude >= 0 ? "E" : "W"
        return String(format: "%.4f %@", abs(pos.longitude), dir)
    }

    var azimuth: String {
        guard let pos = topocentricPosition else { return "--" }
        return String(format: "%.1f", pos.azimuth)
    }

    var elevation: String {
        guard let pos = topocentricPosition else { return "--" }
        return String(format: "%.1f", pos.elevation)
    }

    var range: String {
        guard let pos = topocentricPosition else { return "--" }
        return String(format: "%.1f km", pos.range)
    }

    var isAboveHorizon: Bool {
        topocentricPosition?.isVisible ?? false
    }

    // MARK: - Initialization

    init() {
        loadUSA247()
    }

    // MARK: - Methods

    /// Loads USA-247 satellite for tracking.
    func loadUSA247() {
        loadSatellite(.usa247)
    }

    /// Loads a satellite for tracking.
    func loadSatellite(_ satellite: TrackedSatellite) {
        do {
            tracker = try SatelliteTracker(satellite: satellite)
            errorMessage = nil
            updatePosition()
            calculateGroundTrack()
        } catch {
            errorMessage = "Failed to load satellite: \(error.localizedDescription)"
            tracker = nil
        }
    }

    /// Starts real-time position updates.
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePosition()
            }
        }
    }

    /// Stops real-time position updates.
    func stopTracking() {
        updateTimer?.invalidate()
        updateTimer = nil
        isTracking = false
    }

    /// Updates current satellite position.
    func updatePosition() {
        guard let tracker else { return }

        let now = Date()

        do {
            currentPosition = try tracker.geodeticPosition(at: now)
            topocentricPosition = try tracker.topocentricPosition(at: now, from: observer)
        } catch {
            errorMessage = "Position calculation failed: \(error.localizedDescription)"
        }
    }

    /// Calculates ground track for one orbital period.
    func calculateGroundTrack() {
        guard let tracker else { return }

        let duration = tracker.orbitalPeriodMinutes * 60 // Convert to seconds

        do {
            groundTrack = try tracker.groundTrack(
                from: Date(),
                duration: duration,
                interval: 60
            )
        } catch {
            errorMessage = "Ground track calculation failed"
        }
    }

    /// Sets observer location.
    func setObserver(latitude: Double, longitude: Double, altitude: Double, name: String) {
        observer = GroundStation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitude
        )
        updatePosition()
    }

}
