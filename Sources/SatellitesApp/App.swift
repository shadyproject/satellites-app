import SwiftData
import SwiftUI

@main
struct SatellitesApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([SatelliteModel.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppPreferences.shared)
        }
        .modelContainer(modelContainer)
    }
}
