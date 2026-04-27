import Foundation

/// Generates post-match debrief analysis via the PostPoint backend, with mock fallback.
struct DebriefService {

    // MARK: - Public API

    func generateDebrief(from input: DebriefInput) async throws -> DebriefResult {
        do {
            return try await callBackend(input: input)
        } catch {
            // If the backend is unreachable (e.g. localhost during dev), fall back to mock
            if isConnectionError(error) && APIConfig.baseURL.contains("localhost") {
                return try await mockDebrief(for: input)
            }
            throw error
        }
    }

    // MARK: - Backend Call

    private func callBackend(input: DebriefInput) async throws -> DebriefResult {
        var request = URLRequest(url: APIConfig.debriefURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body = DebriefRequest(
            result: input.result.rawValue,
            score: input.scoreDisplay,
            matchFormat: input.matchFormat.rawValue,
            biggestProblems: input.biggestProblems.map(\.rawValue),
            matchPattern: input.matchPattern.rawValue,
            opponentLevel: input.opponentLevel.rawValue,
            context: buildContextString(from: input)
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DebriefError.networkFailure
        }

        guard httpResponse.statusCode == 200 else {
            // Try to extract error detail from backend
            if let errorBody = try? JSONDecoder().decode(BackendError.self, from: data) {
                throw DebriefError.backendError(errorBody.detail)
            }
            throw DebriefError.networkFailure
        }

        let result = try JSONDecoder().decode(DebriefResponse.self, from: data)

        return DebriefResult(
            primaryIssue: result.primaryIssue,
            explanation: result.explanation,
            nextMatchAdjustment: result.nextMatchAdjustment
        )
    }

    // MARK: - Context Formatting

    private func buildContextString(from input: DebriefInput) -> String? {
        var parts: [String] = input.notableContexts.map(\.rawValue)

        if let note = input.contextNote, !note.isEmpty {
            parts.append(note)
        }

        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }

    // MARK: - Helpers

    private func isConnectionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && [
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
        ].contains(nsError.code)
    }

    // MARK: - Mock Fallback

    private func mockDebrief(for input: DebriefInput) async throws -> DebriefResult {
        try await Task.sleep(for: .seconds(1.5))

        let primary = input.biggestProblems.first ?? .unforcedErrors
        let isLoss = input.result == .lostClose || input.result == .lostBadly

        var (issue, explanation, adjustment) = debriefContent(
            problem: primary,
            result: input.result,
            pattern: input.matchPattern,
            opponentLevel: input.opponentLevel,
            format: input.matchFormat,
            isLoss: isLoss
        )

        if let contextAddition = contextNuance(for: input) {
            explanation += " " + contextAddition
        }

        return DebriefResult(
            primaryIssue: issue,
            explanation: explanation,
            nextMatchAdjustment: adjustment
        )
    }

    private func contextNuance(for input: DebriefInput) -> String? {
        guard input.hasContext else { return nil }

        let contexts = input.notableContexts
        if contexts.contains(.fatigued) || contexts.contains(.sleptPoorly) {
            return "Low energy likely played a role\u{2014}fatigue erodes decision-making before it erodes technique. But that's context, not an excuse."
        }
        if contexts.contains(.stressedOut) {
            return "Coming in stressed or distracted makes it harder to stay present. Your off-court state bled into your on-court play."
        }
        if contexts.contains(.rusty) {
            return "Ring rust is real\u{2014}timing and instincts take a few matches to sharpen. The fact that you played is what matters most right now."
        }
        if contexts.contains(.newEquipment) {
            return "New equipment changes feel and timing. Give yourself 2\u{2013}3 sessions before judging your game with it."
        }
        if contexts.contains(.toughConditions) {
            return "Tough conditions affect everyone\u{2014}the question is who adapts faster. Factor that into your shot selection next time."
        }
        if contexts.contains(.sick) {
            return "Playing while sick limits your physical ceiling. Credit yourself for competing, but don't read too much into the result."
        }

        if let note = input.contextNote, !note.isEmpty {
            return "Your noted context (\"\(note)\") may have been a factor worth tracking over time."
        }

        return nil
    }

    private func debriefContent(
        problem: BiggestProblem,
        result: MatchResult,
        pattern: MatchPattern,
        opponentLevel: OpponentLevel,
        format: MatchFormat,
        isLoss: Bool
    ) -> (String, String, String) {
        switch problem {
        case .unforcedErrors:
            if pattern == .longRallies {
                return (
                    "Patience collapsed in long rallies",
                    isLoss
                        ? "You didn't lose on skill\u{2014}you lost on patience. In long rallies against \(opponentLevel.rawValue.lowercased()) opponents, unforced errors become the deciding factor, and you gave away too many neutral points."
                        : "You pulled out the win, but your unforced errors in long rallies kept it closer than it needed to be. Against \(opponentLevel.rawValue.lowercased()) opponents, those free points add up fast.",
                    "Next match, aim to extend rallies by one extra shot before going aggressive. Make them play one more ball."
                )
            }
            return (
                "Unforced errors at critical moments",
                isLoss
                    ? "The match was there for you, but you gave it away with errors at key moments. Against a \(opponentLevel.rawValue.lowercased()) opponent, you can't afford to hand over free points."
                    : "You won, but too many unforced errors made it harder than it should have been. Tightening up your shot selection would turn close wins into comfortable ones.",
                "Pick one high-error shot and commit to hitting it at 80% power next match. Consistency beats power."
            )

        case .weakFirstServe:
            return (
                "First serve wasn't a weapon",
                isLoss
                    ? "A weak first serve means you're playing second-serve tennis most of the match. Against a \(opponentLevel.rawValue.lowercased()) opponent, that hands them the initiative from the start of every point."
                    : "You won despite a shaky first serve, but you're leaving free points on the table. A reliable first serve changes the entire dynamic of a match.",
                "Focus on placement over power\u{2014}aim for 65%+ first serves in. Pick one spot and commit to it before you toss."
            )

        case .weakSecondServe:
            return (
                "Second serve was a liability",
                isLoss
                    ? "When your second serve is attackable, your opponent starts every point on offense. Against a \(opponentLevel.rawValue.lowercased()) player, a weak second serve is an invitation to dominate the rally."
                    : "You won, but your second serve was a gift. Better opponents will punish it ruthlessly.",
                "Add more spin and depth to your second serve. A second serve that lands deep and kicks is worth more than a first serve that misses."
            )

        case .weakServiceReturn:
            return (
                "Return game broke down",
                isLoss
                    ? "If you can't neutralize the serve, you're fighting uphill on every return game. Against a \(opponentLevel.rawValue.lowercased()) opponent, that pressure compounds fast."
                    : "You pulled through despite a shaky return game. But you made their service games too easy\u{2014}they held without sweating.",
                "Pick a return target before the serve is hit. Just getting the ball back deep and crosscourt changes the point dynamics."
            )

        case .couldntFinishPoints:
            return (
                "Couldn't convert when it mattered",
                isLoss
                    ? "You created opportunities but couldn't put the ball away. In \(pattern.rawValue.lowercased()) patterns, failing to finish means your opponent gets second chances they shouldn't have."
                    : "The win is good, but your inability to close out points efficiently means you're working harder than necessary. That catches up with you against better opponents.",
                "Practice your put-away shot from the position you find yourself in most. One decisive shot is worth three hopeful ones."
            )

        case .positioningMovement:
            let formatContext = format == .doubles ? "In doubles, positioning is everything\u{2014}you can't rely on your partner covering for bad court position." : "Your court coverage directly determines how many balls you can get to quality."
            return (
                "Court positioning was the weak link",
                isLoss
                    ? "Movement and positioning broke down. \(formatContext) Against a \(opponentLevel.rawValue.lowercased()) player, being a half-step late means losing the point."
                    : "You won despite sluggish movement. \(formatContext) Sharper positioning would make these wins feel easier.",
                "After every shot, recover to a split step before your opponent makes contact. Better recovery = better position = easier next shot."
            )

        case .targetedByOpponents:
            return (
                "Opponents found and exploited your weakness",
                isLoss
                    ? "They identified where to attack you and kept going there. When opponents target you consistently, it's a signal that one part of your game is visibly weaker under pressure."
                    : "You survived being targeted, which shows resilience. But they clearly saw something to exploit\u{2014}and better opponents will punish it harder.",
                "Identify which shot they kept attacking. Spend your next practice session specifically on that shot under pressure."
            )

        case .mentalTightNervous:
            return (
                "Nerves dictated the match",
                isLoss
                    ? "This wasn't about technique\u{2014}it was about tension. When you tighten up mentally, your body follows: shorter backswings, tentative footwork, and safe shots that aren't actually safe."
                    : "You gutted out the win despite being tight. That's valuable experience. But playing nervous means you're not playing your game\u{2014}you're playing not to lose.",
                "Before each point, take one full breath and pick a specific target. A clear intention beats a nervous hope every time."
            )

        case .partnerChemistry:
            return (
                "Partner coordination was off",
                isLoss
                    ? "When you and your partner aren't in sync, you're essentially playing 1v2 on every point. Communication gaps and unclear responsibilities cost you easy points."
                    : "You won, but not because of your partnership\u{2014}despite it. Better opponents will exploit the gaps between you and your partner.",
                "Before next match, agree on three things with your partner: who takes middle balls, how you signal switches, and one formation you'll default to under pressure."
            )
        }
    }
}

// MARK: - Request/Response DTOs

private struct DebriefRequest: Encodable {
    let result: String
    let score: String?
    let matchFormat: String
    let biggestProblems: [String]
    let matchPattern: String
    let opponentLevel: String
    let context: String?
}

private struct DebriefResponse: Decodable {
    let primaryIssue: String
    let explanation: String
    let nextMatchAdjustment: String
}

private struct BackendError: Decodable {
    let detail: String
}

// MARK: - Errors

enum DebriefError: LocalizedError {
    case networkFailure
    case backendError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Network error. Check your connection and try again."
        case .backendError(let detail):
            return detail
        case .invalidResponse:
            return "Couldn't parse the response. Try again."
        }
    }
}
