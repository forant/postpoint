import Foundation

struct ScoreLine: Codable, Hashable, Identifiable {
    var id: UUID
    var playerScore: Int
    var opponentScore: Int

    init(id: UUID = UUID(), playerScore: Int = 0, opponentScore: Int = 0) {
        self.id = id
        self.playerScore = playerScore
        self.opponentScore = opponentScore
    }

    /// Whether the user has entered any score in this line
    var hasScore: Bool {
        playerScore > 0 || opponentScore > 0
    }

    var displayString: String {
        "\(playerScore)-\(opponentScore)"
    }
}

extension Array where Element == ScoreLine {
    /// Formatted display string, e.g. "6-4, 3-6, 7-5". Returns nil if no scores entered.
    var displayString: String? {
        let scored = filter { $0.hasScore }
        guard !scored.isEmpty else { return nil }
        return scored.map(\.displayString).joined(separator: ", ")
    }
}
