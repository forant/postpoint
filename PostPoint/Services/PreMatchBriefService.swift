import Foundation

/// Generates pre-match focus bullets via the PostPoint backend.
struct PreMatchBriefService {

    /// Generates 3 coaching bullets for the upcoming match.
    /// Returns cached brief if one exists for this match and was generated today.
    func generate(nextMatch: NextMatch, recentMatches: [Match], opponents: [Opponent] = []) async throws -> PreMatchBrief {
        // Return cached brief if still valid for this match
        if let cached = PreMatchBrief.load(),
           cached.nextMatchId == nextMatch.id,
           Calendar.current.isDateInToday(cached.generatedAt) {
            return cached
        }

        let bullets = try await callBackend(nextMatch: nextMatch, recentMatches: recentMatches, opponents: opponents)

        let brief = PreMatchBrief(
            bullets: bullets,
            nextMatchId: nextMatch.id,
            generatedAt: Date()
        )
        brief.save()
        return brief
    }

    // MARK: - Backend Call

    private func callBackend(nextMatch: NextMatch, recentMatches: [Match], opponents: [Opponent] = []) async throws -> [String] {
        var request = URLRequest(url: APIConfig.preMatchBriefURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let profile = PlayerProfile.load()

        // Build recent debrief summaries (last 3 with results)
        let recentSummaries = recentMatches
            .prefix(3)
            .compactMap { match -> RecentDebriefSummary? in
                guard let input = match.debriefInput, let result = match.debriefResult else { return nil }
                return RecentDebriefSummary(
                    result: input.result.rawValue,
                    score: input.scoreDisplay,
                    primaryIssue: result.primaryIssue,
                    nextMatchAdjustment: result.nextMatchAdjustment,
                    opponentName: match.displayOpponentName
                )
            }

        // Look up scouting notes for the opponent if available
        var scoutingContext: String?
        if let oppName = nextMatch.opponentName {
            let normalized = Opponent.normalize(oppName)
            if let opponent = opponents.first(where: { $0.normalizedName == normalized }) {
                scoutingContext = opponent.scoutingNotes?.promptContext
            }
        }

        let body = PreMatchBriefRequest(
            sport: nextMatch.sport.rawValue,
            opponentName: nextMatch.opponentName,
            playerContext: profile?.promptContext,
            recentDebriefs: recentSummaries.isEmpty ? nil : recentSummaries,
            opponentScouting: scoutingContext
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PreMatchBriefError.networkFailure
        }

        let result = try JSONDecoder().decode(PreMatchBriefResponse.self, from: data)
        guard result.bullets.count == 3 else {
            throw PreMatchBriefError.invalidResponse
        }
        return result.bullets
    }

    // MARK: - Fallback Bullets

    /// Context-aware local fallback if AI generation fails
    static func fallbackBullets(profile: PlayerProfile?) -> [String] {
        var bullets: [String] = []

        // Try to use focus areas for relevant fallback
        if let areas = profile?.focusAreas, !areas.isEmpty {
            let area = areas.first!
            switch area {
            case .serve:
                bullets.append("Start with a reliable first serve placement — aim for 60%+ in today.")
            case .returnOfServe:
                bullets.append("On return, focus on getting the ball deep crosscourt before looking to attack.")
            case .consistency:
                bullets.append("Give yourself 3 feet of margin on every ball until you're in an attacking position.")
            case .netPlay:
                bullets.append("Pick one pattern to approach the net on and commit to it early in the match.")
            case .shotSelection:
                bullets.append("Before each point, decide your pattern for the first 3 shots.")
            case .movement:
                bullets.append("Focus on split-stepping before each of your opponent's shots.")
            case .mental:
                bullets.append("After each point, take a breath and reset before the next one — no carryover.")
            }
        }

        // Fill remaining slots with solid defaults
        let defaults = [
            "Start with high-percentage targets and give yourself margin.",
            "Notice what breaks down first under pressure: serve, return, movement, or shot selection.",
            "After each point, reset quickly and commit to the next pattern.",
            "On big points, choose your pattern before the serve so you're not deciding mid-rally.",
        ]

        for d in defaults where bullets.count < 3 {
            if !bullets.contains(d) {
                bullets.append(d)
            }
        }

        return Array(bullets.prefix(3))
    }
}

// MARK: - Request / Response DTOs

private struct PreMatchBriefRequest: Encodable {
    let sport: String
    let opponentName: String?
    let playerContext: String?
    let recentDebriefs: [RecentDebriefSummary]?
    let opponentScouting: String?
}

private struct RecentDebriefSummary: Encodable {
    let result: String
    let score: String?
    let primaryIssue: String
    let nextMatchAdjustment: String
    let opponentName: String
}

private struct PreMatchBriefResponse: Decodable {
    let bullets: [String]
}

// MARK: - Errors

enum PreMatchBriefError: LocalizedError {
    case networkFailure
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .networkFailure: return "Couldn't reach the server. Check your connection."
        case .invalidResponse: return "Unexpected response format."
        }
    }
}
