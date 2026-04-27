import SwiftUI
import SwiftData

@main
struct PostPointApp: App {
    // Bump this any time you change model fields during development.
    // This forces a clean store reset so you never hit schema mismatch crashes.
    private static let schemaVersion = 11

    @State private var hasCompletedOnboarding = PlayerProfile.hasCompletedOnboarding

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Match.self,
            Opponent.self,
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
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .task { migrateOrphanedMatches() }
                } else {
                    OnboardingView {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .onAppear {
                AnalyticsService.initialize()
                AnalyticsService.track(.appOpened)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Backfills opponentIds for matches that have a name but no linked Opponent.
    /// Safe to run repeatedly — skips matches already linked.
    @MainActor
    private func migrateOrphanedMatches() {
        let context = sharedModelContainer.mainContext
        guard let allMatches = try? context.fetch(FetchDescriptor<Match>()) else { return }

        let orphans = allMatches.filter { $0.opponentIds.isEmpty }

        for match in orphans {
            let names = match.opponentNameSnapshots.isEmpty
                ? [match.opponentName.trimmingCharacters(in: .whitespacesAndNewlines)]
                : match.opponentNameSnapshots

            var ids: [UUID] = []
            var snapshots: [String] = []

            for name in names where !name.isEmpty {
                let opponent = Opponent.findOrCreate(displayName: name, in: context)
                ids.append(opponent.id)
                snapshots.append(opponent.displayName)
            }

            if !ids.isEmpty {
                match.opponentIds = ids
                if match.opponentNameSnapshots.isEmpty {
                    match.opponentNameSnapshots = snapshots
                }
            }
        }

        try? context.save()
    }
}
