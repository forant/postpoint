import Foundation

struct DebriefInput: Codable, Equatable {
    var result: MatchResult
    var scoreLines: [ScoreLine]
    var matchFormat: MatchFormat
    var biggestProblems: [BiggestProblem]
    var matchPattern: MatchPattern
    var opponentLevel: OpponentLevel
    var notableContexts: [NotableContext]
    var contextNote: String?
    // Win-path fields (nil for losses)
    var whatWorked: WhatWorked?
    var improvementAreas: [ImprovementArea]?
    // Schema & sport context
    var sport: SportType = .tennis
    var scoringSystem: ScoringSystem = .tennisSets
    var schemaVersion: Int = 1
    var opponentNames: [String] = []

    /// Formatted score string for display, or nil if no scores entered
    var scoreDisplay: String? {
        scoreLines.displayString
    }

    /// Whether the user provided any context
    var hasContext: Bool {
        !notableContexts.isEmpty || (contextNote != nil && !contextNote!.isEmpty)
    }
}
