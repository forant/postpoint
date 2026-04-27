import Foundation

struct DebriefInput: Codable, Equatable {
    var result: MatchResult
    var scoreLines: [ScoreLine]
    var matchFormat: MatchFormat
    var biggestProblems: [BiggestProblem]
    var matchPattern: MatchPattern
    var opponentLevel: OpponentLevel

    /// Formatted score string for display, or nil if no scores entered
    var scoreDisplay: String? {
        scoreLines.displayString
    }
}
