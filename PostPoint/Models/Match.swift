import Foundation
import SwiftData

enum Sport: String, Codable, CaseIterable, Identifiable {
    case tennis = "Tennis"
    case pickleball = "Pickleball"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tennis: return "tennisball.fill"
        case .pickleball: return "figure.pickleball"
        }
    }
}

@Model
final class Match {
    var id: UUID
    var date: Date
    var opponentName: String
    var sport: Sport
    var notes: String

    // Debrief data (optional — populated when user completes the flow)
    var debriefInput: DebriefInput?
    var debriefResult: DebriefResult?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        opponentName: String,
        sport: Sport,
        notes: String = "",
        debriefInput: DebriefInput? = nil,
        debriefResult: DebriefResult? = nil
    ) {
        self.id = id
        self.date = date
        self.opponentName = opponentName
        self.sport = sport
        self.notes = notes
        self.debriefInput = debriefInput
        self.debriefResult = debriefResult
    }

    /// Short summary for display in match rows
    var resultSummary: String? {
        debriefInput?.result.rawValue
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
                sport: .pickleball,
                notes: "Good dinking game today. Lost focus in the third game."
            ),
            Match(
                date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
                opponentName: "Sam Rivera",
                sport: .tennis,
                notes: "Footwork was off. Need more lateral movement drills."
            ),
        ]
    }
}
