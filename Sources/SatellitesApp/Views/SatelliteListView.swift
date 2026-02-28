import SwiftUI
import SatellitesKit

/// Sidebar view showing a list of available satellites.
struct SatelliteListView: View {
    @Binding var selectedSatellite: SatelliteModel?
    let satellites: [SatelliteModel]

    var body: some View {
        List(satellites, selection: $selectedSatellite) { satellite in
            SatelliteRow(satellite: satellite, isSelected: selectedSatellite?.id == satellite.id)
                .tag(satellite)
        }
        .listStyle(.sidebar)
        .navigationTitle("Satellites")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct SatelliteRow: View {
    let satellite: SatelliteModel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Satellite icon
            ZStack {
                Circle()
                    .fill(isSelected ? .blue : .secondary.opacity(0.3))
                    .frame(width: 32, height: 32)

                Image(systemName: satelliteIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(satellite.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("NORAD \(satellite.noradID)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if satellite.isUserAdded {
                        Text("Custom")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.1), in: Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var satelliteIcon: String {
        let name = satellite.name.lowercased()
        if name.contains("iss") || name.contains("station") {
            return "person.3.fill"
        } else if name.contains("hubble") || name.contains("telescope") {
            return "scope"
        } else if name.contains("noaa") || name.contains("goes") || name.contains("weather") {
            return "cloud.sun.fill"
        } else if name.contains("landsat") || name.contains("terra") || name.contains("earth") {
            return "globe.americas.fill"
        } else if name.contains("starlink") {
            return "antenna.radiowaves.left.and.right"
        } else if name.contains("gps") || name.contains("navstar") {
            return "location.fill"
        } else {
            return "satellite.fill"
        }
    }
}

#Preview {
    NavigationStack {
        SatelliteListView(
            selectedSatellite: .constant(nil),
            satellites: []
        )
    }
    .frame(width: 280)
}
