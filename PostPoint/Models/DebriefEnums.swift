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
    case weakFirstServe = "Weak first serve"
    case weakSecondServe = "Weak second serve"
    case weakServiceReturn = "Weak service return"
    case couldntFinishPoints = "Couldn't finish points"
    case positioningMovement = "Positioning / movement"
    case targetedByOpponents = "Targeted by opponents"
    case mentalTightNervous = "Mental: tight/nervous"
    case partnerChemistry = "Partner chemistry"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .unforcedErrors: return "xmark.circle"
        case .weakFirstServe: return "1.circle"
        case .weakSecondServe: return "2.circle"
        case .weakServiceReturn: return "arrow.uturn.left"
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

// MARK: - Notable Context (optional, select 0-2)

enum NotableContext: String, Codable, CaseIterable, Identifiable {
    case sleptPoorly = "Slept poorly last night"
    case sick = "Sick"
    case stressedOut = "Stressed out"
    case newEquipment = "New equipment"
    case toughConditions = "Windy / tough conditions"
    case fatigued = "Fatigued / low energy"
    case rusty = "Rusty / haven't played recently"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sleptPoorly: return "moon.zzz.fill"
        case .sick: return "facemask.fill"
        case .stressedOut: return "brain"
        case .newEquipment: return "wrench.and.screwdriver"
        case .toughConditions: return "wind"
        case .fatigued: return "battery.25percent"
        case .rusty: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Win Path: What Worked (multi-select)

enum WhatWorked: String, Codable, CaseIterable, Identifiable {
    case serve = "Serve"
    case returnOfServe = "Return"
    case consistency = "Consistency"
    case aggression = "Aggression"
    case netPlay = "Net play"
    case movement = "Movement"
    case mentalToughness = "Mental toughness"
    case strategy = "Strategy"
    case shotSelection = "Shot selection"
    case fitness = "Fitness"
    case adaptability = "Adaptability"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .serve: return "bolt.fill"
        case .returnOfServe: return "arrow.uturn.left"
        case .consistency: return "arrow.left.arrow.right"
        case .aggression: return "flame.fill"
        case .netPlay: return "arrow.up.and.down"
        case .movement: return "figure.walk"
        case .mentalToughness: return "brain.head.profile"
        case .strategy: return "map.fill"
        case .shotSelection: return "scope"
        case .fitness: return "heart.fill"
        case .adaptability: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Win Path: Improvement Area (multi-select up to 2)

enum ImprovementArea: String, Codable, CaseIterable, Identifiable {
    case unforcedErrors = "Unforced errors"
    case serveReturnInconsistency = "Serve/return inconsistency"
    case rushedDecisions = "Rushed decisions"
    case positioningMovement = "Positioning / movement"
    case mentalLapses = "Mental lapses"
    case couldntFinishPoints = "Couldn't finish points"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .unforcedErrors: return "xmark.circle"
        case .serveReturnInconsistency: return "arrow.triangle.2.circlepath"
        case .rushedDecisions: return "hare"
        case .positioningMovement: return "figure.walk"
        case .mentalLapses: return "brain"
        case .couldntFinishPoints: return "flag.slash"
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
