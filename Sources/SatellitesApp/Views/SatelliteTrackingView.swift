import SwiftUI
import SatellitesKit

/// Main view for tracking a satellite.
struct SatelliteTrackingView: View {
    @State private var viewModel = SatelliteViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    positionSection
                    observerSection
                    orbitalParametersSection
                    groundTrackSection
                }
                .padding()
            }
            .navigationTitle("Satellite Tracker")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if viewModel.isTracking {
                            viewModel.stopTracking()
                        } else {
                            viewModel.startTracking()
                        }
                    } label: {
                        Image(systemName: viewModel.isTracking ? "pause.fill" : "play.fill")
                    }
                }
            }
            .onAppear {
                viewModel.startTracking()
            }
            .onDisappear {
                viewModel.stopTracking()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.satelliteName)
                .font(.title)
                .fontWeight(.bold)

            Text("NORAD ID: \(viewModel.noradID)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                StatusIndicator(
                    isActive: viewModel.isAboveHorizon,
                    activeText: "Above Horizon",
                    inactiveText: "Below Horizon"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Current Position")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DataCard(label: "Latitude", value: viewModel.latitude)
                DataCard(label: "Longitude", value: viewModel.longitude)
                DataCard(label: "Altitude", value: viewModel.altitude)
                DataCard(label: "Range", value: viewModel.range)
            }
        }
    }

    private var observerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "From Observer (\(viewModel.observer.name))")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DataCard(label: "Azimuth", value: viewModel.azimuth + "\u{00B0}")
                DataCard(label: "Elevation", value: viewModel.elevation + "\u{00B0}")
                DataCard(label: "Range", value: viewModel.range)
            }
        }
    }

    private var orbitalParametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Orbital Parameters")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DataCard(label: "Period", value: viewModel.orbitalPeriod)
                DataCard(label: "Inclination", value: viewModel.inclinationDegrees + "\u{00B0}")
            }
        }
    }

    private var groundTrackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ground Track")

            if !viewModel.groundTrack.isEmpty {
                GroundTrackMapView(
                    groundTrack: viewModel.groundTrack,
                    currentPosition: viewModel.currentPosition,
                    observer: viewModel.observer
                )
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Calculating ground track...")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

struct DataCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StatusIndicator: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? .green : .red)
                .frame(width: 8, height: 8)
            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }
}

#Preview {
    SatelliteTrackingView()
}
