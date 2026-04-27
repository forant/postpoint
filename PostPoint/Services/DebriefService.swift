import Foundation

/// Generates post-match debrief analysis.
/// Currently returns mocked results; will be replaced with AI API call.
struct DebriefService {

    // MARK: - Future AI Prompt

    /// System prompt for future AI integration:
    ///
    /// "You are a highly perceptive tennis and pickleball coach.
    /// Your job is to analyze a player's match using limited inputs and produce a sharp, specific, and actionable debrief.
    ///
    /// Rules:
    /// - Be concise but insightful
    /// - Avoid generic advice
    /// - Identify ONE primary issue that likely caused the result
    /// - Explain WHY it mattered in the context of the match
    /// - Give ONE clear adjustment for the next match
    /// - If relevant, include a specific tactical suggestion
    ///
    /// Tone:
    /// - Direct, slightly opinionated, but constructive
    /// - Sound like a smart coach, not a motivational speaker
    ///
    /// Do NOT list multiple tips. Focus on the highest-leverage insight."
    ///
    /// User prompt template:
    /// "Match result: {{result}}
    /// Format: {{format}}
    /// Biggest issue: {{issue}}
    /// Match pattern: {{pattern}}
    /// Opponent level: {{opponent_level}}
    ///
    /// Generate a short post-match debrief."

    func generateDebrief(from input: DebriefInput) async throws -> DebriefResult {
        // Simulate network/AI latency
        try await Task.sleep(for: .seconds(1.5))

        return mockDebrief(for: input)
    }

    // MARK: - Mock Generation

    private func mockDebrief(for input: DebriefInput) -> DebriefResult {
        let primary = input.biggestProblems.first ?? .unforcedErrors
        let isLoss = input.result == .lostClose || input.result == .lostBadly

        let (issue, explanation, adjustment) = debriefContent(
            problem: primary,
            result: input.result,
            pattern: input.matchPattern,
            opponentLevel: input.opponentLevel,
            format: input.matchFormat,
            isLoss: isLoss
        )

        return DebriefResult(
            primaryIssue: issue,
            explanation: explanation,
            nextMatchAdjustment: adjustment
        )
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

        case .weakServeReturn:
            return (
                "Serve and return let you down",
                isLoss
                    ? "When the serve and return aren't working, you start every point on the back foot. Against a \(opponentLevel.rawValue.lowercased()) opponent, that's a hole you can't climb out of repeatedly."
                    : "You found a way to win despite a shaky serve and return game. But you're leaving easy points on the table at the start of every rally.",
                "Simplify your service motion. Focus on placement over power\u{2014}hit 70% of first serves in and pick a return target before the ball is struck."
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
