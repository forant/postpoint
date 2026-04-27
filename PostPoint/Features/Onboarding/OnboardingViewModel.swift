import Foundation

@Observable
final class OnboardingViewModel {
    // MARK: - Flow State

    var currentStep = 0
    let totalSteps = 5

    // Step 1: Name
    var firstName: String = ""

    // Step 2: Rating type
    var selectedRatingType: RatingType?

    // Step 3: Rating input
    var utrValue: String = ""
    var selectedUSTALevel: String?
    var selectedPlayerLevel: PlayerLevel?

    // Step 4: Focus areas (pick up to 3)
    var selectedFocusAreas: Set<FocusArea> = []

    // Step 5: Biggest struggle (free text, optional)
    var biggestStruggleText: String = ""

    // Completion
    var isComplete = false

    // MARK: - Navigation

    var progress: Double { Double(currentStep + 1) / Double(totalSteps) }
    var isFirstStep: Bool { currentStep == 0 }
    var isLastStep: Bool { currentStep == totalSteps - 1 }

    var canContinue: Bool {
        switch currentStep {
        case 0: return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return selectedRatingType != nil
        case 2: return ratingInputValid
        case 3: return !selectedFocusAreas.isEmpty && selectedFocusAreas.count <= 3
        case 4: return true  // optional free text
        default: return false
        }
    }

    var isAutoAdvanceStep: Bool {
        switch currentStep {
        case 1: return true  // rating type only
        default: return false
        }
    }

    var showsContinueButton: Bool { !isAutoAdvanceStep }

    private var ratingInputValid: Bool {
        guard let type = selectedRatingType else { return false }
        switch type {
        case .utr:
            guard let val = Double(utrValue) else { return false }
            return val >= 1.0 && val <= 16.5
        case .usta:
            return selectedUSTALevel != nil
        case .selfReported:
            return selectedPlayerLevel != nil
        }
    }

    // MARK: - Actions

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func goNext() {
        guard canContinue else { return }
        if isLastStep {
            completeOnboarding()
        } else {
            currentStep += 1
        }
    }

    func selectAndAdvanceRatingType(_ type: RatingType) {
        selectedRatingType = type
        utrValue = ""
        selectedUSTALevel = nil
        selectedPlayerLevel = nil
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            self.goNext()
        }
    }

    func toggleFocusArea(_ area: FocusArea) {
        if selectedFocusAreas.contains(area) {
            selectedFocusAreas.remove(area)
        } else if selectedFocusAreas.count < 3 {
            selectedFocusAreas.insert(area)
        }
    }

    // MARK: - Completion

    private func completeOnboarding() {
        guard canContinue else { return }

        let rating = PlayerRating(
            ratingType: selectedRatingType ?? .selfReported,
            utrValue: Double(utrValue),
            ustaValue: selectedUSTALevel,
            playerLevel: selectedPlayerLevel
        )

        let trimmedStruggle = biggestStruggleText.trimmingCharacters(in: .whitespacesAndNewlines)

        let profile = PlayerProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            focusAreas: Array(selectedFocusAreas),
            biggestStruggle: trimmedStruggle.isEmpty ? nil : trimmedStruggle,
            ownerUserId: UserIdentityService.shared.anonymousUserId
        )

        profile.save()

        AnalyticsService.track(.onboardingCompleted, properties: [
            "rating_type": rating.ratingType.rawValue,
            "skill_band": rating.skillBand.rawValue,
            "focus_area_count": selectedFocusAreas.count,
            "has_biggest_struggle": !trimmedStruggle.isEmpty,
        ])

        isComplete = true
    }

    // MARK: - USTA Levels

    static let ustaLevels = ["2.0", "2.5", "3.0", "3.5", "4.0", "4.5", "5.0", "5.5"]
}
