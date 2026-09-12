import SwiftUI
import SwiftData

/// The main entry point for the PhotoRoute application.
@main
struct PhotoRouteApp: App {
    /// The shared SwiftData model container used for persisting saved trips.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedTrip.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
