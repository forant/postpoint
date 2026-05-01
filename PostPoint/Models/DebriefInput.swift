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
    /// Legacy single-select field. Kept for backward compatibility with old debriefs.
    var whatWorked: WhatWorked?
    /// Multi-select "what went well" (new). Takes priority over `whatWorked` when present.
    var whatWorkedItems: [WhatWorked]?
    var improvementAreas: [ImprovementArea]?
    // Schema & sport context
    var sport: SportType = .tennis
    var scoringSystem: ScoringSystem = .tennisSets
    var schemaVersion: Int = 1
    var opponentNames: [String] = []

    /// All selected "what worked" items, merging legacy and new fields.
    var allWhatWorked: [WhatWorked] {
        if let items = whatWorkedItems, !items.isEmpty {
            return items
        }
        if let single = whatWorked {
            return [single]
        }
        return []
    }

    /// Formatted score string for display, or nil if no scores entered
    var scoreDisplay: String? {
        scoreLines.displayString
    }

    /// Whether the user provided any context
    var hasContext: Bool {
        !notableContexts.isEmpty || (contextNote != nil && !contextNote!.isEmpty)
    }

    // MARK: - Defensive Decoder

    init(
        result: MatchResult,
        scoreLines: [ScoreLine],
        matchFormat: MatchFormat,
        biggestProblems: [BiggestProblem],
        matchPattern: MatchPattern,
        opponentLevel: OpponentLevel,
        notableContexts: [NotableContext],
        contextNote: String? = nil,
        whatWorked: WhatWorked? = nil,
        whatWorkedItems: [WhatWorked]? = nil,
        improvementAreas: [ImprovementArea]? = nil,
        sport: SportType = .tennis,
        scoringSystem: ScoringSystem = .tennisSets,
        schemaVersion: Int = 1,
        opponentNames: [String] = []
    ) {
        self.result = result
        self.scoreLines = scoreLines
        self.matchFormat = matchFormat
        self.biggestProblems = biggestProblems
        self.matchPattern = matchPattern
        self.opponentLevel = opponentLevel
        self.notableContexts = notableContexts
        self.contextNote = contextNote
        self.whatWorked = whatWorked
        self.whatWorkedItems = whatWorkedItems
        self.improvementAreas = improvementAreas
        self.sport = sport
        self.scoringSystem = scoringSystem
        self.schemaVersion = schemaVersion
        self.opponentNames = opponentNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        result = try c.decode(MatchResult.self, forKey: .result)
        scoreLines = (try? c.decodeIfPresent([ScoreLine].self, forKey: .scoreLines)) ?? []
        matchFormat = try c.decode(MatchFormat.self, forKey: .matchFormat)
        biggestProblems = (try? c.decodeIfPresent([BiggestProblem].self, forKey: .biggestProblems)) ?? []
        matchPattern = try c.decode(MatchPattern.self, forKey: .matchPattern)
        opponentLevel = try c.decode(OpponentLevel.self, forKey: .opponentLevel)
        notableContexts = (try? c.decodeIfPresent([NotableContext].self, forKey: .notableContexts)) ?? []
        contextNote = try? c.decodeIfPresent(String.self, forKey: .contextNote)
        whatWorked = try? c.decodeIfPresent(WhatWorked.self, forKey: .whatWorked)
        whatWorkedItems = try? c.decodeIfPresent([WhatWorked].self, forKey: .whatWorkedItems)
        improvementAreas = try? c.decodeIfPresent([ImprovementArea].self, forKey: .improvementAreas)
        sport = (try? c.decodeIfPresent(SportType.self, forKey: .sport)) ?? .tennis
        scoringSystem = (try? c.decodeIfPresent(ScoringSystem.self, forKey: .scoringSystem)) ?? .tennisSets
        schemaVersion = (try? c.decodeIfPresent(Int.self, forKey: .schemaVersion)) ?? 1
        opponentNames = (try? c.decodeIfPresent([String].self, forKey: .opponentNames)) ?? []
    }
}
