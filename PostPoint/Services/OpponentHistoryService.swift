import Foundation

/// Builds a compact opponent history summary for inclusion in AI debrief prompts.
struct OpponentHistoryService {

    /// Summary of prior history against selected opponent(s).
    struct OpponentHistorySummary {
        let text: String?
        let opponentNamesWithHistory: [String]

        var hasHistory: Bool { text != nil }
    }

    /// Builds a history summary for the given opponent IDs against all prior matches.
    static func buildSummary(
        opponentIds: [UUID],
        opponentNames: [String],
        allMatches: [Match],
        isDoubles: Bool
    ) -> OpponentHistorySummary {
        guard !opponentIds.isEmpty else {
            return OpponentHistorySummary(text: nil, opponentNamesWithHistory: [])
        }

        var sections: [String] = []
        var namesWithHistory: [String] = []

        // Per-opponent summaries
        for (index, opponentId) in opponentIds.enumerated() {
            let name = index < opponentNames.count ? opponentNames[index] : "Opponent \(index + 1)"
            let priorMatches = allMatches
                .filter { $0.opponentIds.contains(opponentId) }
                .sorted { $0.date > $1.date }

            guard !priorMatches.isEmpty else { continue }
            namesWithHistory.append(name)

            let wins = priorMatches.filter(\.isWin).count
            let losses = priorMatches.filter { !$0.isWin && $0.debriefInput != nil }.count
            let record = "\(wins)\u{2013}\(losses)"

            var lines: [String] = []
            lines.append("- \(name): \(priorMatches.count) prior match\(priorMatches.count == 1 ? "" : "es"), user record \(record).")

            // Most recent match details
            if let latest = priorMatches.first {
                var recentParts: [String] = []
                if let result = latest.debriefInput?.result {
                    recentParts.append(result.rawValue.lowercased())
                }
                if let score = latest.debriefInput?.scoreDisplay {
                    recentParts.append(score)
                }
                if !recentParts.isEmpty {
                    lines.append("  Most recent: \(recentParts.joined(separator: ", ")).")
                }
            }

            // Recurring themes from prior debriefs (up to 3 most recent)
            let themes = extractThemes(from: priorMatches)
            if !themes.isEmpty {
                lines.append("  Prior themes: \(themes.joined(separator: "; ")).")
            }

            // Most recent next-match focus
            if let lastFocus = priorMatches.first(where: { $0.debriefResult != nil })?.debriefResult?.nextMatchAdjustment {
                let truncated = String(lastFocus.prefix(150))
                lines.append("  Last recommended focus: \(truncated)")
            }

            sections.append(lines.joined(separator: "\n"))
        }

        // Doubles pair context
        if isDoubles, opponentIds.count == 2 {
            let pairMatches = allMatches.filter { match in
                opponentIds.allSatisfy { match.opponentIds.contains($0) }
            }
            let pairNames = opponentNames.joined(separator: " + ")
            if pairMatches.isEmpty {
                sections.append("- \(pairNames) as a pair: no prior matches together.")
            } else {
                let wins = pairMatches.filter(\.isWin).count
                let losses = pairMatches.filter { !$0.isWin && $0.debriefInput != nil }.count
                sections.append("- \(pairNames) as a pair: \(pairMatches.count) prior match\(pairMatches.count == 1 ? "" : "es"), user record \(wins)\u{2013}\(losses).")
            }
        }

        guard !sections.isEmpty else {
            return OpponentHistorySummary(text: nil, opponentNamesWithHistory: [])
        }

        let header = "Opponent history:"
        let fullText = header + "\n" + sections.joined(separator: "\n")
        return OpponentHistorySummary(text: fullText, opponentNamesWithHistory: namesWithHistory)
    }

    // MARK: - Theme Extraction

    /// Extracts primary issues from up to 3 most recent debriefed matches.
    private static func extractThemes(from matches: [Match]) -> [String] {
        matches
            .prefix(3)
            .compactMap { $0.debriefResult?.primaryIssue }
            .map { issue in
                // Lowercase first char for inline use
                let trimmed = issue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let first = trimmed.first else { return trimmed }
                return String(first).lowercased() + trimmed.dropFirst()
            }
    }
}
