import MapKit
import SwiftUI
import SatellitesKit

/// Map view showing satellite ground track.
struct GroundTrackMapView: View {
    // Single satellite tracking (for selected satellite)
    let groundTrack: [GeodeticPosition]
    let currentPosition: GeodeticPosition?
    let observer: GroundStation
    var satelliteName: String = ""
    var satelliteColor: Color = .blue
    var onSatelliteTapped: (() -> Void)?
    var focusTrigger: Int = 0
    var observerFocusTrigger: Int = 0

    // Multiple satellite display
    var visibleSatellites: [VisibleSatelliteData] = []
    var selectedSatelliteID: Int?
    var onSatelliteSelected: ((Int) -> Void)?

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // Render all visible satellites
            ForEach(visibleSatellites) { satellite in
                let color = Color(hex: satellite.color) ?? .blue
                let isSelected = satellite.id == selectedSatelliteID

                // Ground track polyline segments for this satellite
                ForEach(
                    groundTrackSegments(for: satellite.groundTrack, satelliteID: satellite.id),
                    id: \.0
                ) { segment in
                    MapPolyline(coordinates: segment.1)
                        .stroke(
                            color.opacity(isSelected ? 0.8 : 0.5),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                }

                // Current satellite position
                if let pos = satellite.position {
                    Annotation(
                        "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: pos.latitude,
                            longitude: pos.longitude
                        )
                    ) {
                        SatelliteMarker(
                            name: satellite.name,
                            altitude: pos.altitude,
                            color: color,
                            isSelected: isSelected,
                            onTap: {
                                onSatelliteSelected?(satellite.id)
                            }
                        )
                    }
                }
            }

            // Observer location
            Annotation(
                observer.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: observer.latitude,
                    longitude: observer.longitude
                )
            ) {
                ObserverMarker()
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            focusOnSatellite()
        }
        .onChange(of: focusTrigger) { _, _ in
            focusOnSatellite()
        }
        .onChange(of: observerFocusTrigger) { _, _ in
            focusOnObserver()
        }
    }

    private func focusOnObserver() {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: observer.latitude,
                    longitude: observer.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            ))
        }
    }

    private func focusOnSatellite() {
        // Focus on selected satellite, or first visible one
        let targetPosition: GeodeticPosition?
        if let selectedID = selectedSatelliteID,
           let selected = visibleSatellites.first(where: { $0.id == selectedID }) {
            targetPosition = selected.position
        } else {
            targetPosition = visibleSatellites.first?.position ?? currentPosition
        }

        if let pos = targetPosition {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: pos.latitude,
                        longitude: pos.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
                ))
            }
        }
    }

    /// Splits ground track into segments that don't cross the antimeridian.
    private func groundTrackSegments(for track: [GeodeticPosition], satelliteID: Int) -> [(String, [CLLocationCoordinate2D])] {
        guard !track.isEmpty else { return [] }

        var segments: [(String, [CLLocationCoordinate2D])] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        var segmentIndex = 0

        for i in 0..<track.count {
            let pos = track[i]
            let coord = CLLocationCoordinate2D(
                latitude: pos.latitude,
                longitude: pos.longitude
            )

            if i > 0 {
                let prevPos = track[i - 1]
                let lonDiff = abs(pos.longitude - prevPos.longitude)

                // If longitude jumps more than 180 degrees, start new segment
                if lonDiff > 180 {
                    if !currentSegment.isEmpty {
                        segments.append(("\(satelliteID)-\(segmentIndex)", currentSegment))
                        segmentIndex += 1
                    }
                    currentSegment = [coord]
                    continue
                }
            }

            currentSegment.append(coord)
        }

        if !currentSegment.isEmpty {
            segments.append(("\(satelliteID)-\(segmentIndex)", currentSegment))
        }

        return segments
    }
}

/// Marker for satellite position on map.
struct SatelliteMarker: View {
    var name: String = ""
    var altitude: Double = 0
    var color: Color = .blue
    var isSelected: Bool = true
    var onTap: (() -> Void)?

    @State private var isPulsing = false

    private var altitudeString: String {
        if altitude >= 1000 {
            return String(format: "%.0f km", altitude)
        } else {
            return String(format: "%.1f km", altitude)
        }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: isSelected ? 4 : 2) {
                // Label: larger with altitude when selected, smaller name-only otherwise
                if isSelected {
                    VStack(spacing: 2) {
                        Text(name)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(altitudeString)
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color, in: RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                } else {
                    Text(name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                }

                // Satellite icon with pulse
                ZStack {
                    // Pulse ring (only for selected)
                    if isSelected {
                        Circle()
                            .stroke(color.opacity(0.6), lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .scaleEffect(isPulsing ? 1.4 : 1.0)
                            .opacity(isPulsing ? 0 : 0.8)
                    }

                    // Satellite icon
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: isSelected ? 36 : 24, height: isSelected ? 36 : 24)
                            .shadow(color: .black.opacity(0.4), radius: isSelected ? 4 : 2, y: 2)

                        Image(systemName: "satellite.fill")
                            .font(.system(size: isSelected ? 18 : 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if isSelected {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

/// Marker for observer position on map.
struct ObserverMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.green)
                .frame(width: 16, height: 16)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

            Image(systemName: "person.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    GroundTrackMapView(
        groundTrack: [],
        currentPosition: nil,
        observer: .sanFrancisco,
        visibleSatellites: [
            VisibleSatelliteData(
                id: 25544,
                name: "ISS",
                color: "FF6B35",
                position: GeodeticPosition(
                    latitude: 37.0,
                    longitude: -122.0,
                    altitude: 420,
                    date: Date()
                ),
                groundTrack: []
            )
        ],
        selectedSatelliteID: 25544
    )
}
