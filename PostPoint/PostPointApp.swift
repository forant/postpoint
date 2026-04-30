import SwiftUI
import SwiftData
import UserNotifications

@main
struct PostPointApp: App {
    // Bump this any time you change model fields during development.
    // This forces a clean store reset so you never hit schema mismatch crashes.
    private static let schemaVersion = 13

    @State private var hasCompletedOnboarding = PlayerProfile.hasCompletedOnboarding
    @State private var hasSeenIntro = IntroView.hasSeenIntro
    @State private var showPreMatchBrief = false
    @State private var showSplash = true

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
                if showSplash {
                    SplashScreenView {
                        showSplash = false
                    }
                } else if hasCompletedOnboarding {
                    MainTabView()
                        .task { migrateOrphanedMatches() }
                        .fullScreenCover(isPresented: $showPreMatchBrief) {
                            PreMatchBriefView()
                        }
                } else if !hasSeenIntro {
                    IntroView {
                        withAnimation {
                            hasSeenIntro = true
                        }
                    }
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
                appDelegate.onNotificationTapped = {
                    showPreMatchBrief = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Migrations

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

// MARK: - App Delegate (Notification Handling)

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var onNotificationTapped: (() -> Void)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    /// Called when user taps a notification while app is in foreground or background
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if userInfo["type"] as? String == "pre_match_brief" {
            DispatchQueue.main.async { [weak self] in
                self?.onNotificationTapped?()
            }
        }
        completionHandler()
    }

    /// Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
