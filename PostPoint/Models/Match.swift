import Foundation
import SwiftData

enum SportType: String, Codable, CaseIterable, Identifiable {
    case tennis = "Tennis"
    case pickleball = "Pickleball"
    case padel = "Padel"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tennis: return "tennisball.fill"
        case .pickleball: return "figure.pickleball"
        case .padel: return "figure.racquetball"
        }
    }
}

enum ScoringSystem: String, Codable, CaseIterable, Identifiable {
    case tennisSets = "Tennis Sets"
    case pickleballGames = "Pickleball Games"
    case padelSets = "Padel Sets"
    case custom = "Custom"

    var id: String { rawValue }
}

@Model
final class Match {
    var id: UUID
    var date: Date
    var sport: SportType
    var notes: String
    var matchFormat: MatchFormat?
    var scoringSystem: ScoringSystem

    // Legacy field — kept for backward compatibility with old code paths
    var opponentName: String

    // Multi-opponent support
    var opponentIds: [UUID]
    var opponentNameSnapshots: [String]

    // Debrief data (optional — populated when user completes the flow)
    var debriefInput: DebriefInput?
    var debriefResult: DebriefResult?

    // Owner identity (nil for matches created before identity layer)
    var ownerUserId: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        opponentName: String = "",
        sport: SportType = .tennis,
        notes: String = "",
        matchFormat: MatchFormat? = nil,
        scoringSystem: ScoringSystem = .tennisSets,
        opponentIds: [UUID] = [],
        opponentNameSnapshots: [String] = [],
        debriefInput: DebriefInput? = nil,
        debriefResult: DebriefResult? = nil,
        ownerUserId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.opponentName = opponentName
        self.sport = sport
        self.notes = notes
        self.matchFormat = matchFormat
        self.scoringSystem = scoringSystem
        self.opponentIds = opponentIds
        self.opponentNameSnapshots = opponentNameSnapshots
        self.debriefInput = debriefInput
        self.debriefResult = debriefResult
        self.ownerUserId = ownerUserId
    }

    /// Short summary for display in match rows
    var resultSummary: String? {
        debriefInput?.result.rawValue
    }

    /// Best available display name for opponent(s)
    var displayOpponentName: String {
        if !opponentNameSnapshots.isEmpty {
            return opponentNameSnapshots.joined(separator: " & ")
        }
        let trimmed = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown Opponent" : trimmed
    }

    /// Whether the match has any opponent info
    var hasOpponent: Bool {
        !opponentIds.isEmpty
            || !opponentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether this is a doubles match
    var isDoubles: Bool {
        matchFormat == .doubles || matchFormat == .mixed
    }

    /// Whether the debrief result indicates a win
    var isWin: Bool {
        guard let result = debriefInput?.result else { return false }
        return result == .wonComfortably || result == .wonClose
    }
}

// MARK: - Collection Helpers

extension [Match] {
    /// Returns matches involving a given opponent ID, sorted newest first
    func matches(against opponentId: UUID, limit: Int? = nil) -> [Match] {
        let filtered = self
            .filter { $0.opponentIds.contains(opponentId) }
            .sorted { $0.date > $1.date }
        if let limit { return Array(filtered.prefix(limit)) }
        return filtered
    }
}

// MARK: - Sample Data

extension Match {
    static var sampleMatches: [Match] {
        [
            Match(
                date: Calendar.current.date(byAdding: .hour, value: -2, to: .now)!,
                opponentName: "Alex Chen",
                sport: .tennis,
                notes: "Served well in the first set. Need to work on backhand returns under pressure.",
                matchFormat: .singles,
                opponentNameSnapshots: ["Alex Chen"],
                debriefInput: DebriefInput(
                    result: .wonClose,
                    scoreLines: [
                        ScoreLine(playerScore: 6, opponentScore: 4),
                        ScoreLine(playerScore: 3, opponentScore: 6),
                        ScoreLine(playerScore: 7, opponentScore: 5),
                    ],
                    matchFormat: .singles,
                    biggestProblems: [.unforcedErrors],
                    matchPattern: .longRallies,
                    opponentLevel: .sameLevel,
                    notableContexts: [.fatigued],
                    contextNote: nil
                ),
                debriefResult: DebriefResult(
                    primaryIssue: "Unforced errors in neutral rallies",
                    explanation: "Against an equal opponent in long rallies, the match came down to who blinked first. You won, but your unforced errors kept it closer than it needed to be.",
                    nextMatchAdjustment: "Next match, add one extra shot before going for a winner. Make them play one more ball."
                )
            ),
            Match(
                date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
                opponentName: "Jordan Mills",
                sport: .tennis,
                notes: "Good dinking game today. Lost focus in the third game.",
                matchFormat: .singles,
                opponentNameSnapshots: ["Jordan Mills"]
            ),
            Match(
                date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
                opponentName: "Sam Rivera",
                sport: .tennis,
                notes: "Footwork was off. Need more lateral movement drills.",
                matchFormat: .singles,
                opponentNameSnapshots: ["Sam Rivera"]
            ),
        ]
    }
}
