import SwiftUI
import SatellitesKit

/// Main view for tracking a satellite.
struct SatelliteTrackingView: View {
    @State private var viewModel = SatelliteViewModel()
    @State private var showInfoPanel = false
    @State private var showSidebar = false
    @State private var selectedSatellite: TrackedSatellite? = .usa247
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SatelliteListView(
                selectedSatellite: $selectedSatellite,
                satellites: TrackedSatellite.allSatellites
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            ZStack(alignment: .bottom) {
                // Full-screen map
                GroundTrackMapView(
                    groundTrack: viewModel.groundTrack,
                    currentPosition: viewModel.currentPosition,
                    observer: viewModel.observer,
                    onSatelliteTapped: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoPanel.toggle()
                        }
                    }
                )
                .ignoresSafeArea()

                // Sliding info panel
                if showInfoPanel {
                    SatelliteInfoPanel(
                        viewModel: viewModel,
                        isPresented: $showInfoPanel
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Tracking indicator overlay
                VStack {
                    HStack {
                        TrackingStatusBadge(
                            satelliteName: viewModel.satelliteName,
                            isTracking: viewModel.isTracking,
                            isAboveHorizon: viewModel.isAboveHorizon
                        )
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 50)
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            if columnVisibility == .detailOnly {
                                columnVisibility = .all
                            } else {
                                columnVisibility = .detailOnly
                            }
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .help("Toggle satellite list")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoPanel.toggle()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .help("Toggle satellite info")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedSatellite) { _, newValue in
            if let satellite = newValue {
                viewModel.loadSatellite(satellite)
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

// MARK: - Tracking Status Badge

struct TrackingStatusBadge: View {
    let satelliteName: String
    let isTracking: Bool
    let isAboveHorizon: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isTracking ? (isAboveHorizon ? .green : .orange) : .red)
                .frame(width: 8, height: 8)

            Text(satelliteName)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Satellite Info Panel

struct SatelliteInfoPanel: View {
    let viewModel: SatelliteViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            // Header with mission patch
            HStack(alignment: .top, spacing: 12) {
                // Mission patch
                Image("NROL39PatchLarge")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.satelliteName)
                        .font(.headline)
                    Text("NORAD \(viewModel.noradID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("NROL-39 Mission")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            Divider()

            // Position info
            ScrollView {
                VStack(spacing: 16) {
                    // Current Position Section
                    InfoSection(title: "Position") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            InfoItem(label: "Latitude", value: viewModel.latitude)
                            InfoItem(label: "Longitude", value: viewModel.longitude)
                            InfoItem(label: "Altitude", value: viewModel.altitude)
                            InfoItem(label: "Range", value: viewModel.range)
                        }
                    }

                    // Observer Section
                    InfoSection(title: "From \(viewModel.observer.name)") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            InfoItem(label: "Azimuth", value: viewModel.azimuth + "\u{00B0}")
                            InfoItem(label: "Elevation", value: viewModel.elevation + "\u{00B0}")
                            InfoItem(
                                label: "Visibility",
                                value: viewModel.isAboveHorizon ? "Visible" : "Below Horizon",
                                valueColor: viewModel.isAboveHorizon ? .green : .secondary
                            )
                        }
                    }

                    // Orbital Parameters Section
                    InfoSection(title: "Orbital Parameters") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            InfoItem(label: "Period", value: viewModel.orbitalPeriod)
                            InfoItem(label: "Inclination", value: viewModel.inclinationDegrees + "\u{00B0}")
                        }
                    }
                }
                .padding()
            }
        }
        .frame(maxHeight: 400)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                }
        )
    }
}

// MARK: - Info Section

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Info Item

struct InfoItem: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SatelliteTrackingView()
}
