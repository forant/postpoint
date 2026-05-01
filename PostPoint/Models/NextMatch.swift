import Foundation

/// A lightweight future match object for the "Next Match Loop."
/// Not a completed match — just a reminder/prep object.
struct NextMatch: Codable, Equatable {
    var id: UUID
    var scheduledDate: Date
    var sport: SportType
    var opponentName: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var notificationScheduledAt: Date?

    init(
        id: UUID = UUID(),
        scheduledDate: Date,
        sport: SportType = .tennis,
        opponentName: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notificationScheduledAt: Date? = nil
    ) {
        self.id = id
        self.scheduledDate = scheduledDate
        self.sport = sport
        self.opponentName = opponentName
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notificationScheduledAt = notificationScheduledAt
    }

    // MARK: - Persistence (UserDefaults, single next match)

    private static let storageKey = "PostPoint.nextMatch"

    static func load() -> NextMatch? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(NextMatch.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Whether the next match is scheduled for today or in the future
    var isUpcoming: Bool {
        Calendar.current.isDateInToday(scheduledDate) || scheduledDate > Date()
    }

    /// Whether the next match is strictly in the future (not today).
    /// Used post-debrief to avoid showing today's match as "next" after it's been played.
    var isFutureMatch: Bool {
        !Calendar.current.isDateInToday(scheduledDate) && scheduledDate > Date()
    }

    /// Whether the pre-match brief should be visible (day before through match day)
    var isBriefReady: Bool {
        let calendar = Calendar.current
        if calendar.isDateInToday(scheduledDate) { return true }
        if calendar.isDateInTomorrow(scheduledDate) { return true }
        return false
    }
}

// MARK: - Pre-Match Brief (cached)

struct PreMatchBrief: Codable, Equatable {
    var bullets: [String]
    var nextMatchId: UUID
    var generatedAt: Date

    private static let storageKey = "PostPoint.preMatchBrief"

    static func load() -> PreMatchBrief? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(PreMatchBrief.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
