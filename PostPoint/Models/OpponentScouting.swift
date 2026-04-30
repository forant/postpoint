import Foundation

// MARK: - Scouting Enums

enum OpponentStyle: String, Codable, CaseIterable, Identifiable {
    case aggressive = "Aggressive"
    case defensive = "Defensive"
    case pusher = "Pusher"
    case allCourt = "All-court"

    var id: String { rawValue }
}

enum OpponentWeapon: String, Codable, CaseIterable, Identifiable {
    case forehand = "Forehand"
    case backhand = "Backhand"
    case serve = "Serve"
    case netPlay = "Net play"
    case consistency = "Consistency"

    var id: String { rawValue }
}

enum OpponentWeakness: String, Codable, CaseIterable, Identifiable {
    case backhand = "Backhand"
    case forehand = "Forehand"
    case movement = "Movement"
    case netPlay = "Net play"
    case secondServe = "Second serve"
    case mental = "Mental"

    var id: String { rawValue }
}

enum OpponentTendency: String, Codable, CaseIterable, Identifiable {
    case playsFast = "Plays fast"
    case slowsItDown = "Slows it down"
    case targetsBackhand = "Targets backhand"
    case comesToNet = "Comes to net"
    case avoidsErrors = "Avoids errors"
    case goesForWinners = "Goes for winners"

    var id: String { rawValue }
}

// MARK: - Scouting Notes (stored as Codable on Opponent)

struct OpponentScoutingNotes: Codable, Equatable {
    var style: OpponentStyle?
    var weapon: OpponentWeapon?
    var weakness: OpponentWeakness?
    var tendency: OpponentTendency?
    var note: String?
    var updatedAt: Date
    /// AI-derived observations from match debriefs. Never overwrites user-entered fields above.
    var aiDerivedNotes: [AIDerivedNote]?

    init(
        style: OpponentStyle? = nil,
        weapon: OpponentWeapon? = nil,
        weakness: OpponentWeakness? = nil,
        tendency: OpponentTendency? = nil,
        note: String? = nil,
        updatedAt: Date = Date(),
        aiDerivedNotes: [AIDerivedNote]? = nil
    ) {
        self.style = style
        self.weapon = weapon
        self.weakness = weakness
        self.tendency = tendency
        self.note = note
        self.updatedAt = updatedAt
        self.aiDerivedNotes = aiDerivedNotes
    }

    var isEmpty: Bool {
        style == nil && weapon == nil && weakness == nil && tendency == nil && (note ?? "").isEmpty
    }

    /// Compact text for AI prompt injection
    var promptContext: String? {
        var parts: [String] = []
        if let style { parts.append("Style: \(style.rawValue)") }
        if let weapon { parts.append("Big weapon: \(weapon.rawValue)") }
        if let weakness { parts.append("Weakness: \(weakness.rawValue)") }
        if let tendency { parts.append("Tendency: \(tendency.rawValue)") }
        if let note, !note.isEmpty { parts.append("Notes: \(note)") }
        // Include latest AI-derived observations if available
        if let latest = aiDerivedNotes?.last {
            if !latest.observedStrengths.isEmpty {
                parts.append("AI-observed strengths: \(latest.observedStrengths.joined(separator: ", "))")
            }
            if !latest.observedWeaknesses.isEmpty {
                parts.append("AI-observed weaknesses: \(latest.observedWeaknesses.joined(separator: ", "))")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }

    /// Appends AI-derived insights from a debrief, keeping at most the 3 most recent.
    mutating func appendAIDerivedNote(_ note: AIDerivedNote) {
        var notes = aiDerivedNotes ?? []
        notes.append(note)
        // Keep only the 3 most recent
        if notes.count > 3 {
            notes = Array(notes.suffix(3))
        }
        aiDerivedNotes = notes
    }
}

// MARK: - AI-Derived Note (from match debriefs)

struct AIDerivedNote: Codable, Equatable {
    var matchDate: Date
    var observedStrengths: [String]
    var observedWeaknesses: [String]
    var likelyPatterns: [String]
    var confidence: String

    init(from insights: OpponentInsights, matchDate: Date = Date()) {
        self.matchDate = matchDate
        self.observedStrengths = insights.observedStrengths
        self.observedWeaknesses = insights.observedWeaknesses
        self.likelyPatterns = insights.likelyPatterns
        self.confidence = insights.confidence.rawValue
    }
}
