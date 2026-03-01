import MapKit
import SwiftUI
import SatellitesKit

/// Map view showing satellite ground track.
struct GroundTrackMapView: View {
    let groundTrack: [GeodeticPosition]
    let currentPosition: GeodeticPosition?
    let observer: GroundStation
    var satelliteName: String = ""
    var satelliteColor: Color = .blue
    var onSatelliteTapped: (() -> Void)?
    var focusTrigger: Int = 0

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // Ground track polyline segments
            ForEach(groundTrackSegments, id: \.0) { segment in
                MapPolyline(coordinates: segment.1)
                    .stroke(satelliteColor.opacity(0.7), lineWidth: 2)
            }

            // Current satellite position
            if let pos = currentPosition {
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: pos.latitude,
                        longitude: pos.longitude
                    )
                ) {
                    SatelliteMarker(
                        name: satelliteName,
                        altitude: pos.altitude,
                        color: satelliteColor,
                        onTap: onSatelliteTapped
                    )
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
    }

    private func focusOnSatellite() {
        if let pos = currentPosition {
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
    private var groundTrackSegments: [(Int, [CLLocationCoordinate2D])] {
        guard !groundTrack.isEmpty else { return [] }

        var segments: [(Int, [CLLocationCoordinate2D])] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        var segmentIndex = 0

        for i in 0..<groundTrack.count {
            let pos = groundTrack[i]
            let coord = CLLocationCoordinate2D(
                latitude: pos.latitude,
                longitude: pos.longitude
            )

            if i > 0 {
                let prevPos = groundTrack[i - 1]
                let lonDiff = abs(pos.longitude - prevPos.longitude)

                // If longitude jumps more than 180 degrees, start new segment
                if lonDiff > 180 {
                    if !currentSegment.isEmpty {
                        segments.append((segmentIndex, currentSegment))
                        segmentIndex += 1
                    }
                    currentSegment = [coord]
                    continue
                }
            }

            currentSegment.append(coord)
        }

        if !currentSegment.isEmpty {
            segments.append((segmentIndex, currentSegment))
        }

        return segments
    }
}

/// Marker for satellite position on map.
struct SatelliteMarker: View {
    var name: String = ""
    var altitude: Double = 0
    var color: Color = .blue
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
            VStack(spacing: 4) {
                // Name and altitude label
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

                // Satellite icon with pulse
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(color.opacity(0.6), lineWidth: 2)
                        .frame(width: 48, height: 48)
                        .scaleEffect(isPulsing ? 1.4 : 1.0)
                        .opacity(isPulsing ? 0 : 0.8)

                    // Satellite icon
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                        Image(systemName: "satellite.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
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
        currentPosition: GeodeticPosition(
            latitude: 37.0,
            longitude: -122.0,
            altitude: 1100,
            date: Date()
        ),
        observer: .sanFrancisco,
        satelliteName: "ISS",
        satelliteColor: .orange,
        onSatelliteTapped: {}
    )
}
