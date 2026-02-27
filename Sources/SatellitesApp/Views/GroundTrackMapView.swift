import MapKit
import SwiftUI
import SatellitesKit

/// Map view showing satellite ground track.
struct GroundTrackMapView: View {
    let groundTrack: [GeodeticPosition]
    let currentPosition: GeodeticPosition?
    let observer: GroundStation

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // Ground track polyline segments
            ForEach(groundTrackSegments, id: \.0) { segment in
                MapPolyline(coordinates: segment.1)
                    .stroke(.blue.opacity(0.7), lineWidth: 2)
            }

            // Current satellite position
            if let pos = currentPosition {
                Annotation(
                    "Satellite",
                    coordinate: CLLocationCoordinate2D(
                        latitude: pos.latitude,
                        longitude: pos.longitude
                    )
                ) {
                    SatelliteMarker()
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
        .onAppear {
            if let pos = currentPosition {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: pos.latitude,
                        longitude: pos.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
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
    var body: some View {
        ZStack {
            Circle()
                .fill(.red)
                .frame(width: 20, height: 20)

            Image(systemName: "airplane")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-45))
        }
        .shadow(radius: 3)
    }
}

/// Marker for observer position on map.
struct ObserverMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.green)
                .frame(width: 16, height: 16)

            Image(systemName: "person.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(radius: 2)
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
        observer: .sanFrancisco
    )
}
