import Foundation
import SwiftData
import SwiftUI

@Observable
final class HomeViewModel {
    var showingDebrief = false
    var showingScoutOpponent = false
    var showingPreMatchBrief = false
    var showingAccount = false
    var showOnboardingResetAlert = false

    var nextMatch: NextMatch?

    func loadNextMatch() {
        nextMatch = NextMatch.load()
    }

    /// Whether the pre-match brief should be surfaced on the home screen.
    /// Shows starting the day before the match through match day.
    var shouldShowPreMatchCard: Bool {
        nextMatch?.isBriefReady == true
    }

    func matchCount(_ matches: [Match]) -> Int {
        matches.count
    }

    func recentMatches(_ matches: [Match], limit: Int = 5) -> [Match] {
        Array(matches.prefix(limit))
    }
}
