import SwiftData
import SwiftUI
import SatellitesKit

/// Main view for tracking a satellite.
struct SatelliteTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppPreferences.self) private var preferences
    @Query(sort: \SatelliteModel.name) private var satellites: [SatelliteModel]

    @State private var viewModel = SatelliteViewModel()
    @State private var locationManager = LocationManager()
    @State private var showInfoPanel = false
    @State private var selectedSatellite: SatelliteModel?
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var focusTrigger = 0
    @State private var hasInitialized = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SatelliteListView(
                selectedSatellite: $selectedSatellite,
                satellites: satellites
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            ZStack(alignment: .bottom) {
                // Full-screen map
                GroundTrackMapView(
                    groundTrack: viewModel.groundTrack,
                    currentPosition: viewModel.currentPosition,
                    observer: viewModel.observer,
                    satelliteName: selectedSatellite?.name ?? "",
                    satelliteColor: selectedSatellite?.color ?? .blue,
                    onSatelliteTapped: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoPanel.toggle()
                        }
                    },
                    focusTrigger: focusTrigger
                )
                .ignoresSafeArea()

                // Sliding info panel
                if showInfoPanel {
                    SatelliteInfoPanel(
                        viewModel: viewModel,
                        satelliteColor: selectedSatellite?.color ?? .blue,
                        isPresented: $showInfoPanel
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Tracking indicator overlay
                VStack {
                    HStack {
                        TrackingStatusBadge(
                            satelliteName: viewModel.satelliteName,
                            satelliteColor: selectedSatellite?.color ?? .blue,
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
        }
        .toolbar {
            #if !os(macOS)
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
            }
            #endif

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
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedSatellite) { _, newValue in
            if let satellite = newValue {
                let tracked = satellite.toTrackedSatellite()
                viewModel.loadSatellite(tracked)
                preferences.selectedSatelliteID = satellite.noradID
                // Delay focus to allow position calculation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusTrigger += 1
                }
            }
        }
        .onChange(of: columnVisibility) { _, newValue in
            preferences.sidebarVisible = (newValue != .detailOnly)
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            // When authorization is granted, fetch location
            if locationManager.isAuthorized && !preferences.hasSetLocationFromDevice {
                Task {
                    await locationManager.updateObserverLocation(preferences: preferences)
                    viewModel.observer = preferences.observer
                }
            }
        }
        .task {
            await initializeApp()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
    }

    private func initializeApp() async {
        guard !hasInitialized else { return }
        hasInitialized = true

        // Seed default satellites if needed
        let catalog = SatelliteCatalog(modelContainer: modelContext.container)
        do {
            try catalog.seedDefaultsIfNeeded()
        } catch {
            print("Failed to seed satellites: \(error)")
        }

        // Get user location if not already set
        if !preferences.hasSetLocationFromDevice {
            await requestUserLocation()
        }

        // Restore saved preferences
        viewModel.observer = preferences.observer

        // Restore sidebar state
        if preferences.sidebarVisible {
            columnVisibility = .all
        }

        // Select saved satellite or default
        let savedID = preferences.selectedSatelliteID
        if let saved = satellites.first(where: { $0.noradID == savedID }) {
            selectedSatellite = saved
        } else if let first = satellites.first {
            selectedSatellite = first
        }

        viewModel.startTracking()
    }

    private func requestUserLocation() async {
        // If already authorized, get location immediately
        if locationManager.isAuthorized {
            await locationManager.updateObserverLocation(preferences: preferences)
            viewModel.observer = preferences.observer
        } else {
            // Request authorization - onChange handler will fetch location when granted
            locationManager.requestAuthorization()
        }
    }
}

// MARK: - Tracking Status Badge

struct TrackingStatusBadge: View {
    let satelliteName: String
    let satelliteColor: Color
    let isTracking: Bool
    let isAboveHorizon: Bool

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(satelliteColor)
                    .frame(width: 12, height: 12)

                Circle()
                    .fill(isTracking ? (isAboveHorizon ? .green : .orange) : .red)
                    .frame(width: 6, height: 6)
            }

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
    let satelliteColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            // Header with satellite icon
            HStack(alignment: .top, spacing: 12) {
                // Satellite icon
                ZStack {
                    Circle()
                        .fill(satelliteColor)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    Image(systemName: "satellite.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.satelliteName)
                        .font(.headline)
                    Text("NORAD \(viewModel.noradID)")
                        .font(.caption)
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
        .modelContainer(for: SatelliteModel.self, inMemory: true)
        .environment(AppPreferences.shared)
}
