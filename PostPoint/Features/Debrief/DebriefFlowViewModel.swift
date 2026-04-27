import Foundation
import SwiftData

@Observable
final class DebriefFlowViewModel {
    // MARK: - Flow State

    /// Steps: 0=Result, 1=Score, 2=Format, 3=BiggestProblems, 4=Pattern, 5=OpponentLevel
    var currentStep = 0
    let totalSteps = 6

    // Answers
    var selectedResult: MatchResult?
    var scoreLines: [ScoreLine] = [ScoreLine()]
    var selectedFormat: MatchFormat?
    var selectedProblems: Set<BiggestProblem> = []
    var selectedPattern: MatchPattern?
    var selectedOpponentLevel: OpponentLevel?

    // Completion state
    var isGenerating = false
    var debriefResult: DebriefResult?
    var error: String?

    private let debriefService = DebriefService()

    // MARK: - Step Classification

    /// Steps that auto-advance on selection (single-select, no text input)
    var isAutoAdvanceStep: Bool {
        switch currentStep {
        case 0, 2, 4, 5: return true  // Result, Format, Pattern, OpponentLevel
        case 1, 3: return false        // Score (builder), BiggestProblems (multi-select)
        default: return false
        }
    }

    /// Whether the current step needs a Continue button
    var showsContinueButton: Bool { !isAutoAdvanceStep }

    var canContinue: Bool {
        switch currentStep {
        case 0: return selectedResult != nil
        case 1: return true  // Score is optional
        case 2: return selectedFormat != nil
        case 3: return !selectedProblems.isEmpty && selectedProblems.count <= 2
        case 4: return selectedPattern != nil
        case 5: return selectedOpponentLevel != nil
        default: return false
        }
    }

    var isFirstStep: Bool { currentStep == 0 }
    var isLastStep: Bool { currentStep == totalSteps - 1 }
    var progress: Double { Double(currentStep + 1) / Double(totalSteps) }

    // MARK: - Filtered Options

    /// Filter out doubles-only problems when Singles is selected
    var availableProblems: [BiggestProblem] {
        if selectedFormat == .singles {
            return BiggestProblem.allCases.filter {
                $0 != .partnerChemistry && $0 != .targetedByOpponents
            }
        }
        return BiggestProblem.allCases
    }

    // MARK: - Navigation

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func goNext() {
        guard canContinue else { return }
        if isLastStep {
            generateDebrief()
        } else {
            currentStep += 1
        }
    }

    /// Called by single-select questions to set value and auto-advance
    func selectAndAdvance<T: Equatable>(_ value: T, binding: ReferenceWritableKeyPath<DebriefFlowViewModel, T?>) {
        self[keyPath: binding] = value
        // Small delay so the user sees their selection highlight
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            self.goNext()
        }
    }

    // MARK: - Selection Helpers

    func toggleProblem(_ problem: BiggestProblem) {
        if selectedProblems.contains(problem) {
            selectedProblems.remove(problem)
        } else if selectedProblems.count < 2 {
            selectedProblems.insert(problem)
        }
    }

    // MARK: - Score Helpers

    /// Only keep score lines that have actual scores entered
    private var enteredScoreLines: [ScoreLine] {
        scoreLines.filter { $0.hasScore }
    }

    // MARK: - Debrief Generation

    private func generateDebrief() {
        guard let input = buildInput() else { return }
        isGenerating = true
        error = nil

        Task { @MainActor in
            do {
                let result = try await debriefService.generateDebrief(from: input)
                self.debriefResult = result
            } catch {
                self.error = "Failed to generate debrief. Please try again."
            }
            self.isGenerating = false
        }
    }

    func buildInput() -> DebriefInput? {
        guard
            let result = selectedResult,
            let format = selectedFormat,
            let pattern = selectedPattern,
            let level = selectedOpponentLevel,
            !selectedProblems.isEmpty
        else { return nil }

        return DebriefInput(
            result: result,
            scoreLines: enteredScoreLines,
            matchFormat: format,
            biggestProblems: Array(selectedProblems),
            matchPattern: pattern,
            opponentLevel: level
        )
    }

    /// Saves the completed debrief as a new Match in SwiftData
    func saveMatch(to modelContext: ModelContext, sport: Sport) {
        guard let input = buildInput(), let result = debriefResult else { return }

        let scoreNote = input.scoreDisplay.map { " (\($0))" } ?? ""
        let match = Match(
            opponentName: "Opponent",
            sport: sport,
            notes: "\(input.result.rawValue)\(scoreNote) \u{2022} \(input.matchPattern.rawValue)",
            debriefInput: input,
            debriefResult: result
        )

        modelContext.insert(match)
    }
}
