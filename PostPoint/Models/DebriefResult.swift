import Foundation

struct DebriefResult: Codable, Equatable {
    var primaryIssue: String
    var explanation: String
    var nextMatchAdjustment: String
    var createdAt: Date
    var aiContext: AIContext?

    init(
        primaryIssue: String,
        explanation: String,
        nextMatchAdjustment: String,
        createdAt: Date = Date(),
        aiContext: AIContext? = nil
    ) {
        self.primaryIssue = primaryIssue
        self.explanation = explanation
        self.nextMatchAdjustment = nextMatchAdjustment
        self.createdAt = createdAt
        self.aiContext = aiContext
    }
}

struct AIContext: Codable, Equatable {
    var sport: SportType
    var promptVersion: String
    var generatedAt: Date
    var model: String?
}
