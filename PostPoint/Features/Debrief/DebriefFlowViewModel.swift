import Foundation
import SwiftData
import Mixpanel

@Observable
final class DebriefFlowViewModel {
    // MARK: - Flow State

    /// Steps: 0=Result, 1=Score, 2=Format, 3=Opponent(s), then outcome-dependent:
    /// Loss: 4=BiggestProblems, 5=Pattern, 6=OpponentLevel, 7=Context
    /// Win:  4=WhatWorked, 5=ImprovementAreas, 6=Pattern, 7=OpponentLevel, 8=Context
    var currentStep = 0

    // Answers
    var selectedResult: MatchResult?
    var scoreLines: [ScoreLine] = [ScoreLine()]
    var selectedFormat: MatchFormat?
    var opponentName: String = ""
    var selectedOpponentId: UUID?
    var secondOpponentName: String = ""
    var secondSelectedOpponentId: UUID?
    var selectedProblems: Set<BiggestProblem> = []
    var selectedPattern: MatchPattern?
    var selectedOpponentLevel: OpponentLevel?
    var selectedContexts: Set<NotableContext> = []
    var contextNote: String = ""
    // Win-path answers
    var selectedWhatWorked: Set<WhatWorked> = []
    var selectedImprovementAreas: Set<ImprovementArea> = []

    // Completion state
    var isGenerating = false
    var debriefResult: DebriefResult?
    var error: String?

    /// Set by the view before generation so history can be gathered
    var allMatches: [Match] = []
    var allOpponents: [Opponent] = []

    private let debriefService = DebriefService()
    private var generationStartTime: Date?

    // MARK: - Outcome Helpers

    var isWin: Bool {
        selectedResult == .wonComfortably || selectedResult == .wonClose
    }

    var isDoubles: Bool {
        selectedFormat == .doubles || selectedFormat == .mixed
    }

    var totalSteps: Int { isWin ? 9 : 8 }

    /// Maps the current step index to a semantic step identity
    enum StepKind {
        case result, score, format, opponent
        case biggestProblems          // loss only
        case whatWorked, improvementAreas  // win only
        case pattern, opponentLevel, context
    }

    var currentStepKind: StepKind {
        switch currentStep {
        case 0: return .result
        case 1: return .score
        case 2: return .format
        case 3: return .opponent
        case 4: return isWin ? .whatWorked : .biggestProblems
        case 5: return isWin ? .improvementAreas : .pattern
        case 6: return isWin ? .pattern : .opponentLevel
        case 7: return isWin ? .opponentLevel : .context
        case 8: return .context  // win path only
        default: return .result
        }
    }

    // MARK: - Step Classification

    /// Steps that auto-advance on selection (single-select, no text input)
    var isAutoAdvanceStep: Bool {
        switch currentStepKind {
        case .result, .format, .pattern, .opponentLevel: return true
        case .opponent, .score, .biggestProblems, .whatWorked, .improvementAreas, .context: return false
        }
    }

    /// Whether the current step needs a Continue button
    var showsContinueButton: Bool { !isAutoAdvanceStep }

    var canContinue: Bool {
        switch currentStepKind {
        case .result: return selectedResult != nil
        case .score: return true
        case .format: return selectedFormat != nil
        case .opponent: return true  // Opponent is optional
        case .biggestProblems: return !selectedProblems.isEmpty && selectedProblems.count <= 2
        case .whatWorked: return !selectedWhatWorked.isEmpty
        case .improvementAreas: return !selectedImprovementAreas.isEmpty && selectedImprovementAreas.count <= 2
        case .pattern: return selectedPattern != nil
        case .opponentLevel: return selectedOpponentLevel != nil
        case .context: return true
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

        trackQuestionAnswered()

        if isLastStep {
            generateDebrief(allMatches: allMatches)
        } else {
            currentStep += 1
        }
    }

    /// Called by single-select questions to set value and auto-advance
    func selectAndAdvance<T: Equatable>(_ value: T, binding: ReferenceWritableKeyPath<DebriefFlowViewModel, T?>) {
        self[keyPath: binding] = value
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

    func toggleWhatWorked(_ item: WhatWorked) {
        if selectedWhatWorked.contains(item) {
            selectedWhatWorked.remove(item)
        } else if selectedWhatWorked.count < 4 {
            selectedWhatWorked.insert(item)
        }
    }

    func toggleImprovementArea(_ area: ImprovementArea) {
        if selectedImprovementAreas.contains(area) {
            selectedImprovementAreas.remove(area)
        } else if selectedImprovementAreas.count < 2 {
            selectedImprovementAreas.insert(area)
        }
    }

    // MARK: - Opponent Helpers

    /// Collected opponent names for prompt context
    var opponentNames: [String] {
        var names: [String] = []
        let first = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !first.isEmpty { names.append(first) }
        if isDoubles {
            let second = secondOpponentName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !second.isEmpty { names.append(second) }
        }
        return names
    }

    /// Resolved opponent IDs (only those already selected from existing opponents)
    var resolvedOpponentIds: [UUID] {
        var ids: [UUID] = []
        if let id = selectedOpponentId { ids.append(id) }
        if isDoubles, let id = secondSelectedOpponentId { ids.append(id) }
        return ids
    }

    // MARK: - Score Helpers

    private var enteredScoreLines: [ScoreLine] {
        scoreLines.filter { $0.hasScore }
    }

    // MARK: - Opponent History

    /// Summary built at generation time, stored for UI display
    var opponentHistorySummary: OpponentHistoryService.OpponentHistorySummary?

    // MARK: - Debrief Generation

    func generateDebrief(allMatches: [Match] = []) {
        guard let input = buildInput() else { return }
        isGenerating = true
        error = nil
        generationStartTime = Date()

        AnalyticsService.track(.debriefSubmitted, properties: analyticsProperties)

        // Gather opponent history
        let resolvedIds = resolvedOpponentIds
        let summary = OpponentHistoryService.buildSummary(
            opponentIds: resolvedIds,
            opponentNames: opponentNames,
            allMatches: allMatches,
            isDoubles: isDoubles,
            opponents: allOpponents
        )
        opponentHistorySummary = summary

        let profile = PlayerProfile.load()

        #if DEBUG
        if let profile {
            print("[Debrief] PlayerProfile included: ratingType=\(profile.rating.ratingType.rawValue), skillBand=\(profile.rating.skillBand.rawValue), focusAreas=\(profile.focusAreas.count), hasBiggestStruggle=\(profile.biggestStruggle != nil)")
        } else {
            print("[Debrief] No PlayerProfile found — generating without profile context.")
        }
        #endif

        Task { @MainActor in
            do {
                let result = try await debriefService.generateDebrief(
                    from: input,
                    opponentHistory: summary.text,
                    playerProfile: profile
                )
                self.debriefResult = result

                var props = analyticsProperties
                if let start = generationStartTime {
                    props["generation_duration_ms"] = Int(Date().timeIntervalSince(start) * 1000)
                }
                props["has_opponent_history"] = summary.hasHistory
                props["has_player_profile"] = profile != nil
                props["prompt_version"] = "opponent-insights-v1"
                if let profile {
                    props["rating_type"] = profile.rating.ratingType.rawValue
                    props["focus_area_count"] = profile.focusAreas.count
                    props["has_biggest_struggle"] = profile.biggestStruggle != nil
                }
                AnalyticsService.track(.debriefGenerated, properties: props)
                AnalyticsService.track(.debriefViewed, properties: props)

                // insight_moment_reached
                let debriefCount = allMatches.filter { $0.hasDebrief }.count + 1
                AnalyticsService.track(.insightMomentReached, properties: [
                    "completed_match_count": allMatches.count + 1,
                    "completed_debrief_count": debriefCount,
                    "sport": "tennis",
                    "match_format": input.matchFormat.rawValue,
                ])
            } catch let debriefError as DebriefError {
                self.error = debriefError.errorDescription
                var props = analyticsProperties
                props["error_type"] = debriefError.errorDescription ?? "unknown"
                AnalyticsService.track(.debriefGenerationFailed, properties: props)
            } catch {
                self.error = "Something went wrong. Please try again."
                var props = analyticsProperties
                props["error_type"] = "unknown"
                AnalyticsService.track(.debriefGenerationFailed, properties: props)
            }
            self.isGenerating = false
        }
    }

    func retry() {
        generateDebrief(allMatches: allMatches)
    }

    func buildInput() -> DebriefInput? {
        guard
            let result = selectedResult,
            let format = selectedFormat,
            let pattern = selectedPattern,
            let level = selectedOpponentLevel
        else { return nil }

        // Validate path-specific requirements
        if isWin {
            guard !selectedWhatWorked.isEmpty, !selectedImprovementAreas.isEmpty else { return nil }
        } else {
            guard !selectedProblems.isEmpty else { return nil }
        }

        let trimmedNote = contextNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let whatWorkedArray = isWin ? Array(selectedWhatWorked) : nil

        return DebriefInput(
            result: result,
            scoreLines: enteredScoreLines,
            matchFormat: format,
            biggestProblems: isWin ? [] : Array(selectedProblems),
            matchPattern: pattern,
            opponentLevel: level,
            notableContexts: Array(selectedContexts),
            contextNote: trimmedNote.isEmpty ? nil : trimmedNote,
            whatWorked: whatWorkedArray?.first,
            whatWorkedItems: whatWorkedArray,
            improvementAreas: isWin ? Array(selectedImprovementAreas) : nil,
            sport: .tennis,
            scoringSystem: .tennisSets,
            schemaVersion: 1,
            opponentNames: opponentNames
        )
    }

    /// Saves the completed debrief as a new Match in SwiftData.
    /// Resolves opponents: reuses existing by ID or normalized name, or creates new.
    func saveMatch(to modelContext: ModelContext) {
        guard let input = buildInput(), let result = debriefResult else { return }

        var resolvedIds: [UUID] = []
        var snapshots: [String] = []

        // Resolve primary opponent
        resolveOpponent(
            name: opponentName,
            selectedId: selectedOpponentId,
            into: &resolvedIds,
            snapshots: &snapshots,
            context: modelContext
        )

        // Resolve second opponent (doubles)
        if isDoubles {
            resolveOpponent(
                name: secondOpponentName,
                selectedId: secondSelectedOpponentId,
                into: &resolvedIds,
                snapshots: &snapshots,
                context: modelContext
            )
        }

        let scoreNote = input.scoreDisplay.map { " (\($0))" } ?? ""
        let match = Match(
            opponentName: snapshots.joined(separator: " & "),
            sport: .tennis,
            notes: "\(input.result.rawValue)\(scoreNote) \u{2022} \(input.matchPattern.rawValue)",
            matchFormat: input.matchFormat,
            scoringSystem: .tennisSets,
            result: input.result,
            matchPattern: input.matchPattern,
            opponentLevel: input.opponentLevel,
            scoreDisplay: input.scoreDisplay,
            opponentIds: resolvedIds,
            opponentNameSnapshots: snapshots,
            primaryIssue: result.primaryIssue,
            explanation: result.explanation,
            nextMatchAdjustment: result.nextMatchAdjustment,
            debriefInputArchive: input,
            debriefResultArchive: result,
            ownerUserId: UserIdentityService.shared.anonymousUserId
        )

        modelContext.insert(match)

        // Append AI-derived opponent insights (does not overwrite user scouting data)
        if let insights = result.opponentInsights, insights.hasContent {
            appendInsightsToOpponents(
                insights: insights,
                resolvedIds: resolvedIds,
                context: modelContext
            )
        }

        // Track match saved
        AnalyticsService.track(.matchSaved, properties: [
            "sport": "tennis",
            "match_format": input.matchFormat.rawValue,
            "scoring_system": ScoringSystem.tennisSets.rawValue,
            "opponent_count": resolvedIds.count,
            "has_score": input.scoreDisplay != nil,
            "result": input.result.rawValue,
            "score_set_count": enteredScoreLines.count,
        ])
    }

    private func resolveOpponent(
        name: String,
        selectedId: UUID?,
        into ids: inout [UUID],
        snapshots: inout [String],
        context: ModelContext
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existingId = selectedId {
            ids.append(existingId)
            snapshots.append(trimmed)
        } else {
            let opponent = Opponent.findOrCreate(displayName: trimmed, in: context)
            ids.append(opponent.id)
            snapshots.append(opponent.displayName)
        }
    }

    // MARK: - AI Opponent Insights

    private func appendInsightsToOpponents(
        insights: OpponentInsights,
        resolvedIds: [UUID],
        context: ModelContext
    ) {
        let note = AIDerivedNote(from: insights)
        for id in resolvedIds {
            guard let opponent = allOpponents.first(where: { $0.id == id }) else { continue }
            if opponent.scoutingNotes == nil {
                opponent.scoutingNotes = OpponentScoutingNotes(aiDerivedNotes: [note])
            } else {
                opponent.scoutingNotes?.appendAIDerivedNote(note)
            }
        }
        try? context.save()
    }

    // MARK: - Analytics

    /// Common properties for debrief funnel events
    var analyticsProperties: [String: MixpanelType] {
        var props: [String: MixpanelType] = [
            "sport": "tennis",
            "question_count": totalSteps,
            "schema_version": 1,
            "prompt_version": "opponent-context-v1",
        ]
        if let format = selectedFormat {
            props["match_format"] = format.rawValue
        }
        if let result = selectedResult {
            props["result"] = result.rawValue
        }
        props["opponent_count"] = opponentNames.count
        return props
    }

    private func trackQuestionAnswered() {
        var props = analyticsProperties
        props["step"] = currentStep
        props["step_kind"] = String(describing: currentStepKind)
        props["answered_question_count"] = currentStep + 1
        AnalyticsService.track(.debriefQuestionAnswered, properties: props)
    }
}
