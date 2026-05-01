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

    // MARK: - Match Metadata (flattened, queryable)

    var matchFormat: MatchFormat?
    var scoringSystem: ScoringSystem
    var result: MatchResult?
    var matchPattern: MatchPattern?
    var opponentLevel: OpponentLevel?
    var scoreDisplay: String?

    // MARK: - Opponent (flattened)

    /// Primary display name (joined for doubles, e.g. "Alex & Jordan")
    var opponentName: String
    /// Individual opponent SwiftData IDs (optional — SwiftData stores empty arrays as NULL)
    var opponentIds: [UUID]?
    /// Snapshot of opponent names at match time
    var opponentNameSnapshots: [String]?

    // MARK: - Debrief Result (flattened, displayed in rows/detail)

    var primaryIssue: String?
    var explanation: String?
    var nextMatchAdjustment: String?

    // MARK: - Archival Blobs (full debrief data for history/AI context)

    /// Full debrief input snapshot — archived for opponent history and AI prompt context.
    var debriefInputArchive: DebriefInput?
    /// Full debrief result snapshot — archived for opponent history and AI-derived insights.
    var debriefResultArchive: DebriefResult?

    // MARK: - Identity

    var ownerUserId: String?

    // MARK: - Schema

    /// Local data schema version. Allows future migrations on a per-record basis.
    var dataVersion: Int = 2

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        opponentName: String = "",
        sport: SportType = .tennis,
        notes: String = "",
        matchFormat: MatchFormat? = nil,
        scoringSystem: ScoringSystem = .tennisSets,
        result: MatchResult? = nil,
        matchPattern: MatchPattern? = nil,
        opponentLevel: OpponentLevel? = nil,
        scoreDisplay: String? = nil,
        opponentIds: [UUID]? = nil,
        opponentNameSnapshots: [String]? = nil,
        primaryIssue: String? = nil,
        explanation: String? = nil,
        nextMatchAdjustment: String? = nil,
        debriefInputArchive: DebriefInput? = nil,
        debriefResultArchive: DebriefResult? = nil,
        ownerUserId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.opponentName = opponentName
        self.sport = sport
        self.notes = notes
        self.matchFormat = matchFormat
        self.scoringSystem = scoringSystem
        self.result = result
        self.matchPattern = matchPattern
        self.opponentLevel = opponentLevel
        self.scoreDisplay = scoreDisplay
        self.opponentIds = opponentIds
        self.opponentNameSnapshots = opponentNameSnapshots
        self.primaryIssue = primaryIssue
        self.explanation = explanation
        self.nextMatchAdjustment = nextMatchAdjustment
        self.debriefInputArchive = debriefInputArchive
        self.debriefResultArchive = debriefResultArchive
        self.ownerUserId = ownerUserId
    }

    // MARK: - Safe Array Access

    var safeOpponentIds: [UUID] {
        get { opponentIds ?? [] }
        set { opponentIds = newValue }
    }

    var safeOpponentNameSnapshots: [String] {
        get { opponentNameSnapshots ?? [] }
        set { opponentNameSnapshots = newValue }
    }

    // MARK: - Computed Helpers

    var resultSummary: String? {
        result?.rawValue
    }

    var displayOpponentName: String {
        let snapshots = safeOpponentNameSnapshots
        if !snapshots.isEmpty {
            return snapshots.joined(separator: " & ")
        }
        let trimmed = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown Opponent" : trimmed
    }

    var hasOpponent: Bool {
        !safeOpponentIds.isEmpty
            || !opponentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isDoubles: Bool {
        matchFormat == .doubles || matchFormat == .mixed
    }

    var isWin: Bool {
        guard let result else { return false }
        return result == .wonComfortably || result == .wonClose
    }

    /// Whether this match has a completed debrief
    var hasDebrief: Bool {
        primaryIssue != nil
    }
}

// MARK: - Collection Helpers

extension [Match] {
    func matches(against opponentId: UUID, limit: Int? = nil) -> [Match] {
        let filtered = self
            .filter { $0.safeOpponentIds.contains(opponentId) }
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
                notes: "Served well in the first set.",
                matchFormat: .singles,
                result: .wonClose,
                matchPattern: .longRallies,
                opponentLevel: .sameLevel,
                scoreDisplay: "6-4, 3-6, 7-5",
                opponentNameSnapshots: ["Alex Chen"],
                primaryIssue: "Unforced errors in neutral rallies",
                explanation: "Against an equal opponent in long rallies, the match came down to who blinked first.",
                nextMatchAdjustment: "Next match, add one extra shot before going for a winner."
            ),
            Match(
                date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
                opponentName: "Jordan Mills",
                sport: .tennis,
                notes: "Good dinking game today.",
                matchFormat: .singles,
                opponentNameSnapshots: ["Jordan Mills"]
            ),
            Match(
                date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
                opponentName: "Sam Rivera",
                sport: .tennis,
                notes: "Footwork was off.",
                matchFormat: .singles,
                opponentNameSnapshots: ["Sam Rivera"]
            ),
        ]
    }
}
