import Foundation

struct DebriefResult: Codable, Equatable {
    var primaryIssue: String
    var explanation: String
    var nextMatchAdjustment: String
    var createdAt: Date

    init(
        primaryIssue: String,
        explanation: String,
        nextMatchAdjustment: String,
        createdAt: Date = Date()
    ) {
        self.primaryIssue = primaryIssue
        self.explanation = explanation
        self.nextMatchAdjustment = nextMatchAdjustment
        self.createdAt = createdAt
    }
}
