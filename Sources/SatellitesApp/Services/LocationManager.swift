import CoreLocation
import Foundation
import SatellitesKit

/// Manages location services for determining observer position.
@MainActor
@Observable
final class LocationManager: NSObject {
    // MARK: - Properties

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var currentLocation: CLLocation?
    private(set) var lastError: Error?

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return true
        default:
            return false
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Requests location authorization from the user.
    func requestAuthorization() {
        #if os(macOS)
        manager.requestWhenInUseAuthorization()
        #else
        manager.requestWhenInUseAuthorization()
        #endif
    }

    /// Requests the current location once.
    func requestLocation() async throws -> CLLocation {
        guard isAuthorized else {
            requestAuthorization()
            throw LocationError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    /// Converts a CLLocation to a GroundStation.
    func toGroundStation(_ location: CLLocation, name: String = "Current Location") -> GroundStation {
        GroundStation(
            name: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeMeters: max(0, location.altitude)
        )
    }

    /// Gets current location and updates preferences.
    func updateObserverLocation(preferences: AppPreferences) async {
        do {
            let location = try await requestLocation()
            currentLocation = location

            // Reverse geocode to get location name
            let name = await reverseGeocode(location) ?? "Current Location"
            let groundStation = toGroundStation(location, name: name)

            preferences.observer = groundStation
            preferences.hasSetLocationFromDevice = true
        } catch {
            lastError = error
            print("Failed to get location: \(error)")
        }
    }

    /// Reverse geocodes a location to get a place name.
    private func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                if let city = placemark.locality {
                    return city
                } else if let area = placemark.administrativeArea {
                    return area
                } else if let country = placemark.country {
                    return country
                }
            }
        } catch {
            print("Reverse geocoding failed: \(error)")
        }

        return nil
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            currentLocation = location
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
        }
    }
}

// MARK: - Errors

enum LocationError: Error, LocalizedError {
    case notAuthorized
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access not authorized"
        case .locationUnavailable:
            return "Unable to determine location"
        }
    }
}
