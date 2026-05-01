import Foundation

struct DebriefResult: Codable, Equatable {
    var primaryIssue: String
    var explanation: String
    var nextMatchAdjustment: String
    var createdAt: Date
    var aiContext: AIContext?
    var opponentInsights: OpponentInsights?

    init(
        primaryIssue: String,
        explanation: String,
        nextMatchAdjustment: String,
        createdAt: Date = Date(),
        aiContext: AIContext? = nil,
        opponentInsights: OpponentInsights? = nil
    ) {
        self.primaryIssue = primaryIssue
        self.explanation = explanation
        self.nextMatchAdjustment = nextMatchAdjustment
        self.createdAt = createdAt
        self.aiContext = aiContext
        self.opponentInsights = opponentInsights
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        primaryIssue = (try? c.decodeIfPresent(String.self, forKey: .primaryIssue)) ?? ""
        explanation = (try? c.decodeIfPresent(String.self, forKey: .explanation)) ?? ""
        nextMatchAdjustment = (try? c.decodeIfPresent(String.self, forKey: .nextMatchAdjustment)) ?? ""
        createdAt = (try? c.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        aiContext = try? c.decodeIfPresent(AIContext.self, forKey: .aiContext)
        opponentInsights = try? c.decodeIfPresent(OpponentInsights.self, forKey: .opponentInsights)
    }
}

struct AIContext: Codable, Equatable {
    var sport: SportType
    var promptVersion: String
    var generatedAt: Date
    var model: String?

    init(sport: SportType, promptVersion: String, generatedAt: Date, model: String? = nil) {
        self.sport = sport
        self.promptVersion = promptVersion
        self.generatedAt = generatedAt
        self.model = model
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sport = (try? c.decodeIfPresent(SportType.self, forKey: .sport)) ?? .tennis
        promptVersion = (try? c.decodeIfPresent(String.self, forKey: .promptVersion)) ?? "unknown"
        generatedAt = (try? c.decodeIfPresent(Date.self, forKey: .generatedAt)) ?? Date()
        model = try? c.decodeIfPresent(String.self, forKey: .model)
    }
}

// MARK: - Opponent Insights (AI-generated, stored per debrief)

enum InsightConfidence: String, Codable, Equatable {
    case low
    case medium
    case high
}

struct OpponentInsights: Codable, Equatable {
    var observedStrengths: [String]
    var observedWeaknesses: [String]
    var likelyPatterns: [String]
    var recommendedApproachNextTime: [String]
    var confidence: InsightConfidence
    var evidenceNotes: [String]

    /// Whether there are any meaningful insights to display
    var hasContent: Bool {
        !observedStrengths.isEmpty
        || !observedWeaknesses.isEmpty
        || !likelyPatterns.isEmpty
        || !recommendedApproachNextTime.isEmpty
    }

    init(
        observedStrengths: [String] = [],
        observedWeaknesses: [String] = [],
        likelyPatterns: [String] = [],
        recommendedApproachNextTime: [String] = [],
        confidence: InsightConfidence = .low,
        evidenceNotes: [String] = []
    ) {
        self.observedStrengths = observedStrengths
        self.observedWeaknesses = observedWeaknesses
        self.likelyPatterns = likelyPatterns
        self.recommendedApproachNextTime = recommendedApproachNextTime
        self.confidence = confidence
        self.evidenceNotes = evidenceNotes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        observedStrengths = (try? c.decodeIfPresent([String].self, forKey: .observedStrengths)) ?? []
        observedWeaknesses = (try? c.decodeIfPresent([String].self, forKey: .observedWeaknesses)) ?? []
        likelyPatterns = (try? c.decodeIfPresent([String].self, forKey: .likelyPatterns)) ?? []
        recommendedApproachNextTime = (try? c.decodeIfPresent([String].self, forKey: .recommendedApproachNextTime)) ?? []
        confidence = (try? c.decodeIfPresent(InsightConfidence.self, forKey: .confidence)) ?? .low
        evidenceNotes = (try? c.decodeIfPresent([String].self, forKey: .evidenceNotes)) ?? []
    }
}
