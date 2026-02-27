import SwiftUI
import SatellitesKit

/// Sidebar view showing a list of available satellites.
struct SatelliteListView: View {
    @Binding var selectedSatellite: TrackedSatellite?
    let satellites: [TrackedSatellite]

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
    let satellite: TrackedSatellite
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Satellite icon
            Circle()
                .fill(isSelected ? .blue : .secondary.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "satellite.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(satellite.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("NORAD \(satellite.noradID)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SatelliteListView(
            selectedSatellite: .constant(.usa247),
            satellites: TrackedSatellite.allSatellites
        )
    }
    .frame(width: 280)
}
