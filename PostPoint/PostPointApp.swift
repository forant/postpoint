import SwiftUI
import SwiftData

@main
struct PostPointApp: App {
    // Bump this any time you change model fields during development.
    // This forces a clean store reset so you never hit schema mismatch crashes.
    private static let schemaVersion = 8

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Match.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Check if schema version changed since last launch
        let key = "PostPoint.schemaVersion"
        let lastVersion = UserDefaults.standard.integer(forKey: key)
        if lastVersion != schemaVersion {
            // Wipe old store to avoid runtime crashes from schema changes
            let url = modelConfiguration.url
            for ext in ["", "-shm", "-wal"] {
                let fileURL = ext.isEmpty ? url : url.deletingPathExtension().appendingPathExtension(url.pathExtension + ext)
                try? FileManager.default.removeItem(at: fileURL)
            }
            UserDefaults.standard.set(schemaVersion, forKey: key)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
