import Foundation
import SwiftData

@Model
final class Opponent {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var normalizedName: String
    var createdAt: Date

    // Future fields (unused for now)
    var email: String?
    var phone: String?
    var externalUserId: String?

    init(displayName: String) {
        self.id = UUID()
        self.displayName = displayName
        self.normalizedName = Opponent.normalize(displayName)
        self.createdAt = Date()
    }

    static func normalize(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

// MARK: - Lookup Helpers

extension Opponent {
    /// Find an existing opponent by normalized name, or create a new one
    static func findOrCreate(
        displayName: String,
        in context: ModelContext
    ) -> Opponent {
        let normalized = Opponent.normalize(displayName)

        let descriptor = FetchDescriptor<Opponent>(
            predicate: #Predicate { $0.normalizedName == normalized }
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let opponent = Opponent(displayName: displayName)
        context.insert(opponent)
        return opponent
    }
}
