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
    /// Includes scouting notes when available.
    static func buildSummary(
        opponentIds: [UUID],
        opponentNames: [String],
        allMatches: [Match],
        isDoubles: Bool,
        opponents: [Opponent] = []
    ) -> OpponentHistorySummary {
        guard !opponentIds.isEmpty else {
            return OpponentHistorySummary(text: nil, opponentNamesWithHistory: [])
        }

        var sections: [String] = []
        var namesWithHistory: [String] = []

        for (index, opponentId) in opponentIds.enumerated() {
            let name = index < opponentNames.count ? opponentNames[index] : "Opponent \(index + 1)"
            let priorMatches = allMatches
                .filter { $0.safeOpponentIds.contains(opponentId) }
                .sorted { $0.date > $1.date }

            if priorMatches.isEmpty {
                if let opponent = opponents.first(where: { $0.id == opponentId }),
                   let scoutContext = opponent.scoutingNotes?.promptContext {
                    sections.append("- \(name): no prior matches.\n  Scouting notes: \(scoutContext)")
                    namesWithHistory.append(name)
                }
                continue
            }
            namesWithHistory.append(name)

            let wins = priorMatches.filter(\.isWin).count
            let losses = priorMatches.filter { !$0.isWin && $0.hasDebrief }.count
            let record = "\(wins)\u{2013}\(losses)"

            var lines: [String] = []
            lines.append("- \(name): \(priorMatches.count) prior match\(priorMatches.count == 1 ? "" : "es"), user record \(record).")

            if let latest = priorMatches.first {
                var recentParts: [String] = []
                if let result = latest.result {
                    recentParts.append(result.rawValue.lowercased())
                }
                if let score = latest.scoreDisplay {
                    recentParts.append(score)
                }
                if !recentParts.isEmpty {
                    lines.append("  Most recent: \(recentParts.joined(separator: ", ")).")
                }
            }

            let themes = extractThemes(from: priorMatches)
            if !themes.isEmpty {
                lines.append("  Prior themes: \(themes.joined(separator: "; ")).")
            }

            if let lastFocus = priorMatches.first(where: { $0.hasDebrief })?.nextMatchAdjustment {
                let truncated = String(lastFocus.prefix(150))
                lines.append("  Last recommended focus: \(truncated)")
            }

            if let opponent = opponents.first(where: { $0.id == opponentId }),
               let scoutContext = opponent.scoutingNotes?.promptContext {
                lines.append("  Scouting notes: \(scoutContext)")
            }

            sections.append(lines.joined(separator: "\n"))
        }

        if isDoubles, opponentIds.count == 2 {
            let pairMatches = allMatches.filter { match in
                opponentIds.allSatisfy { match.safeOpponentIds.contains($0) }
            }
            let pairNames = opponentNames.joined(separator: " + ")
            if pairMatches.isEmpty {
                sections.append("- \(pairNames) as a pair: no prior matches together.")
            } else {
                let wins = pairMatches.filter(\.isWin).count
                let losses = pairMatches.filter { !$0.isWin && $0.hasDebrief }.count
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

    private static func extractThemes(from matches: [Match]) -> [String] {
        matches
            .prefix(3)
            .compactMap { $0.primaryIssue }
            .map { issue in
                let trimmed = issue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let first = trimmed.first else { return trimmed }
                return String(first).lowercased() + trimmed.dropFirst()
            }
    }
}
