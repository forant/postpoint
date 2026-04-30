import Foundation
import Mixpanel

// MARK: - Event Definitions

enum AnalyticsEvent: String {
    // App lifecycle
    case appOpened = "app_opened"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"

    // Match funnel
    case matchEntryStarted = "match_entry_started"
    case matchSaved = "match_saved"

    // Debrief funnel
    case debriefStarted = "debrief_started"
    case debriefQuestionAnswered = "debrief_question_answered"
    case debriefSubmitted = "debrief_submitted"
    case debriefGenerated = "debrief_generated"
    case debriefGenerationFailed = "debrief_generation_failed"
    case debriefViewed = "debrief_viewed"

    // Opponent scouting
    case opponentScouted = "opponent_scouted"

    // Next match loop
    case nextMatchSet = "next_match_set"
    case nextMatchSkipped = "next_match_skipped"
    case preMatchBriefViewed = "pre_match_brief_viewed"
    case preMatchBriefGenerated = "pre_match_brief_generated"
    case preMatchBriefFailed = "pre_match_brief_failed"

    // Paywall-ready
    case insightMomentReached = "insight_moment_reached"
}

// MARK: - Analytics Service

enum AnalyticsService {
    private static var isInitialized = false

    /// Call once at app launch
    static func initialize() {
        guard let token = mixpanelToken, !token.isEmpty else {
            #if DEBUG
            print("[Analytics] No Mixpanel token found — analytics disabled.")
            #endif
            return
        }

        Mixpanel.initialize(token: token, trackAutomaticEvents: false)
        isInitialized = true

        let userId = UserIdentityService.shared.anonymousUserId
        Mixpanel.mainInstance().identify(distinctId: userId)

        #if DEBUG
        print("[Analytics] Mixpanel initialized. User: \(userId)")
        #endif
    }

    /// Track an event with optional properties
    static func track(_ event: AnalyticsEvent, properties: [String: MixpanelType]? = nil) {
        var merged = baseProperties
        if let properties {
            for (key, value) in properties {
                merged[key] = value
            }
        }

        #if DEBUG
        let propsString = merged.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
        print("[Analytics] \(event.rawValue) {\(propsString)}")
        #endif

        guard isInitialized else { return }
        Mixpanel.mainInstance().track(event: event.rawValue, properties: merged)
    }

    // MARK: - Base Properties

    private static var baseProperties: [String: MixpanelType] {
        var props: [String: MixpanelType] = [
            "source": "ios",
        ]
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            props["app_version"] = version
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            props["build_number"] = build
        }
        return props
    }

    // MARK: - Token

    private static var mixpanelToken: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return dict["MIXPANEL_TOKEN"] as? String
    }
}
