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
}

struct AIContext: Codable, Equatable {
    var sport: SportType
    var promptVersion: String
    var generatedAt: Date
    var model: String?
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
}
