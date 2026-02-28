import Foundation
import SatellitesKit

/// Manages app preferences using UserDefaults.
@MainActor
@Observable
final class AppPreferences {
    // MARK: - Singleton

    static let shared = AppPreferences()

    // MARK: - Keys

    private enum Keys {
        static let selectedSatelliteID = "selectedSatelliteID"
        static let observerLatitude = "observerLatitude"
        static let observerLongitude = "observerLongitude"
        static let observerAltitude = "observerAltitude"
        static let observerName = "observerName"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let sidebarVisible = "sidebarVisible"
    }

    // MARK: - Properties

    private let defaults = UserDefaults.standard

    /// The NORAD ID of the currently selected satellite.
    var selectedSatelliteID: Int {
        get { defaults.integer(forKey: Keys.selectedSatelliteID) }
        set { defaults.set(newValue, forKey: Keys.selectedSatelliteID) }
    }

    /// Observer ground station location.
    var observer: GroundStation {
        get {
            let lat = defaults.object(forKey: Keys.observerLatitude) as? Double ?? 37.7749
            let lon = defaults.object(forKey: Keys.observerLongitude) as? Double ?? -122.4194
            let alt = defaults.object(forKey: Keys.observerAltitude) as? Double ?? 16
            let name = defaults.string(forKey: Keys.observerName) ?? "San Francisco"

            return GroundStation(
                name: name,
                latitude: lat,
                longitude: lon,
                altitudeMeters: alt
            )
        }
        set {
            defaults.set(newValue.latitude, forKey: Keys.observerLatitude)
            defaults.set(newValue.longitude, forKey: Keys.observerLongitude)
            defaults.set(newValue.altitudeMeters, forKey: Keys.observerAltitude)
            defaults.set(newValue.name, forKey: Keys.observerName)
        }
    }

    /// Whether the user has completed initial onboarding/setup.
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    /// Whether the sidebar is visible.
    var sidebarVisible: Bool {
        get { defaults.bool(forKey: Keys.sidebarVisible) }
        set { defaults.set(newValue, forKey: Keys.sidebarVisible) }
    }

    // MARK: - Initialization

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.selectedSatelliteID: 39462, // USA-247
            Keys.observerLatitude: 37.7749,
            Keys.observerLongitude: -122.4194,
            Keys.observerAltitude: 16.0,
            Keys.observerName: "San Francisco",
            Keys.hasCompletedOnboarding: false,
            Keys.sidebarVisible: false,
        ])
    }

    // MARK: - Methods

    /// Resets all preferences to defaults.
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        registerDefaults()
    }
}
