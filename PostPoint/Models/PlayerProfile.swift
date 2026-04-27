import Foundation

// MARK: - Rating Type

enum RatingType: String, Codable, CaseIterable, Identifiable {
    case utr = "UTR"
    case usta = "USTA / NTRP"
    case selfReported = "Self-reported"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .utr: return "number.circle"
        case .usta: return "star.circle"
        case .selfReported: return "person.circle"
        }
    }
}

// MARK: - Player Level (self-reported)

enum PlayerLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case competitive = "Competitive / Tournament"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        case .competitive: return "4.circle"
        }
    }
}

// MARK: - Focus Area

enum FocusArea: String, Codable, CaseIterable, Identifiable {
    case consistency = "Consistency"
    case serve = "Serve"
    case returnOfServe = "Return of serve"
    case netPlay = "Net play"
    case shotSelection = "Shot selection"
    case movement = "Movement"
    case mental = "Mental game"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .consistency: return "arrow.left.arrow.right"
        case .serve: return "bolt.fill"
        case .returnOfServe: return "arrow.uturn.left"
        case .netPlay: return "arrow.up.and.down"
        case .shotSelection: return "scope"
        case .movement: return "figure.walk"
        case .mental: return "brain.head.profile"
        }
    }
}

// MARK: - Skill Band (internal normalization)

enum SkillBand: String, Codable {
    case beginner
    case intermediate
    case advanced
    case competitive

    static func from(ratingType: RatingType, utrValue: Double?, ustaValue: String?, playerLevel: PlayerLevel?) -> SkillBand {
        switch ratingType {
        case .utr:
            guard let utr = utrValue else { return .intermediate }
            if utr < 5.0 { return .beginner }
            if utr < 9.0 { return .intermediate }
            if utr < 12.0 { return .advanced }
            return .competitive

        case .usta:
            guard let ntrp = ustaValue, let value = Double(ntrp) else { return .intermediate }
            if value <= 3.0 { return .beginner }
            if value <= 4.0 { return .intermediate }
            if value == 4.5 { return .advanced }
            return .competitive

        case .selfReported:
            guard let level = playerLevel else { return .intermediate }
            switch level {
            case .beginner: return .beginner
            case .intermediate: return .intermediate
            case .advanced: return .advanced
            case .competitive: return .competitive
            }
        }
    }
}

// MARK: - Player Rating

struct PlayerRating: Codable, Equatable {
    var ratingType: RatingType
    var utrValue: Double?
    var ustaValue: String?
    var playerLevel: PlayerLevel?

    var displayString: String {
        switch ratingType {
        case .utr:
            if let utr = utrValue { return "UTR \(String(format: "%.1f", utr))" }
            return "UTR"
        case .usta:
            if let ntrp = ustaValue { return "NTRP \(ntrp)" }
            return "NTRP"
        case .selfReported:
            return playerLevel?.rawValue ?? "Self-reported"
        }
    }

    var skillBand: SkillBand {
        SkillBand.from(ratingType: ratingType, utrValue: utrValue, ustaValue: ustaValue, playerLevel: playerLevel)
    }
}

// MARK: - Player Profile

struct PlayerProfile: Codable, Equatable {
    var firstName: String
    var rating: PlayerRating
    var focusAreas: [FocusArea]
    var biggestStruggle: String?
    var ownerUserId: String?

    /// Compact text summary for injection into AI prompts
    var promptContext: String {
        var lines: [String] = []
        lines.append("Player: \(firstName)")
        lines.append("Level: \(rating.displayString) (\(rating.skillBand.rawValue))")
        if !focusAreas.isEmpty {
            lines.append("Focus areas: \(focusAreas.map(\.rawValue).joined(separator: ", "))")
        }
        if let biggestStruggle, !biggestStruggle.isEmpty {
            lines.append("Biggest struggle: \(biggestStruggle)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Persistence

    private static let storageKey = "PostPoint.playerProfile"

    static func load() -> PlayerProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        guard var profile = try? JSONDecoder().decode(PlayerProfile.self, from: data) else { return nil }

        // Backfill ownerUserId for profiles created before identity layer
        if profile.ownerUserId == nil {
            profile.ownerUserId = UserIdentityService.shared.anonymousUserId
            profile.save()
        }

        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.data(forKey: storageKey) != nil
    }
}
