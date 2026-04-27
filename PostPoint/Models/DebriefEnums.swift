import Foundation

// MARK: - Question 1: Match Result

enum MatchResult: String, Codable, CaseIterable, Identifiable {
    case wonComfortably = "Won comfortably"
    case wonClose = "Won close"
    case lostClose = "Lost close"
    case lostBadly = "Lost badly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wonComfortably: return "hand.thumbsup.fill"
        case .wonClose: return "hand.thumbsup"
        case .lostClose: return "hand.thumbsdown"
        case .lostBadly: return "hand.thumbsdown.fill"
        }
    }
}

// MARK: - Question 2: Match Format

enum MatchFormat: String, Codable, CaseIterable, Identifiable {
    case singles = "Singles"
    case doubles = "Doubles"
    case mixed = "Mixed / rotating partners"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .singles: return "person.fill"
        case .doubles: return "person.2.fill"
        case .mixed: return "person.2.slash.fill"
        }
    }
}

// MARK: - Question 3: Biggest Problem (select 1-2)

enum BiggestProblem: String, Codable, CaseIterable, Identifiable {
    case unforcedErrors = "Unforced errors"
    case weakServeReturn = "Weak serve/return"
    case couldntFinishPoints = "Couldn't finish points"
    case positioningMovement = "Positioning / movement"
    case targetedByOpponents = "Targeted by opponents"
    case mentalTightNervous = "Mental: tight/nervous"
    case partnerChemistry = "Partner chemistry"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .unforcedErrors: return "xmark.circle"
        case .weakServeReturn: return "arrow.up.right"
        case .couldntFinishPoints: return "flag.slash"
        case .positioningMovement: return "figure.walk"
        case .targetedByOpponents: return "target"
        case .mentalTightNervous: return "brain.head.profile"
        case .partnerChemistry: return "person.2.wave.2"
        }
    }
}

// MARK: - Question 4: Match Pattern

enum MatchPattern: String, Codable, CaseIterable, Identifiable {
    case longRallies = "Long rallies"
    case quickPoints = "Quick points: serve/return"
    case defending = "I was defending a lot"
    case attackingButMissing = "I was attacking but missing"
    case backAndForthAtNet = "Back-and-forth at net"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .longRallies: return "arrow.left.arrow.right"
        case .quickPoints: return "bolt.fill"
        case .defending: return "shield.fill"
        case .attackingButMissing: return "scope"
        case .backAndForthAtNet: return "arrow.up.and.down"
        }
    }
}

// MARK: - Question 5: Opponent Level

enum OpponentLevel: String, Codable, CaseIterable, Identifiable {
    case muchBetter = "Much better"
    case slightlyBetter = "Slightly better"
    case sameLevel = "Same level"
    case slightlyWorse = "Slightly worse"
    case muchWorse = "Much worse"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .muchBetter: return "chevron.up.2"
        case .slightlyBetter: return "chevron.up"
        case .sameLevel: return "equal"
        case .slightlyWorse: return "chevron.down"
        case .muchWorse: return "chevron.down.2"
        }
    }
}
