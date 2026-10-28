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
            print("Failed to initialize persistent ModelContainer: \(error). Falling back to in-memory container.")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Fatal: Unable to create even an in-memory ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
