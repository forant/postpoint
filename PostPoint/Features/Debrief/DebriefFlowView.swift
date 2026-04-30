import SwiftUI
import SwiftData

struct DebriefFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.date, order: .reverse) private var allMatches: [Match]
    @Query(sort: \Opponent.createdAt, order: .reverse) private var allOpponents: [Opponent]
    @State private var viewModel = DebriefFlowViewModel()
    @State private var showNextMatchPrompt = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    generatingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if showNextMatchPrompt {
                    ScrollView {
                        NextMatchPromptView {
                            dismiss()
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)
                    }
                } else if let result = viewModel.debriefResult {
                    DebriefSummaryView(
                        result: result,
                        opponentHistoryNames: viewModel.opponentHistorySummary?.opponentNamesWithHistory ?? []
                    ) {
                        viewModel.saveMatch(to: modelContext)
                        withAnimation {
                            showNextMatchPrompt = true
                        }
                    }
                } else {
                    questionFlow
                }
            }
            .navigationTitle("Debrief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: allMatches) {
                viewModel.allMatches = allMatches
            }
            .onChange(of: allOpponents) {
                viewModel.allOpponents = allOpponents
            }
            .onAppear {
                viewModel.allMatches = allMatches
                viewModel.allOpponents = allOpponents
                AnalyticsService.track(.debriefStarted)
                AnalyticsService.track(.matchEntryStarted)
            }
        }
    }

    // MARK: - Question Flow

    private var questionFlow: some View {
        VStack(spacing: 0) {
            ProgressView(value: viewModel.progress)
                .tint(AppColors.primary)
                .padding(.horizontal, AppSpacing.md)

            Text("Question \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)
                .padding(.top, AppSpacing.sm)

            ScrollView {
                currentQuestion
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)
            }

            navigationBar
        }
    }

    // MARK: - Questions

    @ViewBuilder
    private var currentQuestion: some View {
        switch viewModel.currentStepKind {
        case .result:
            DebriefQuestionView(
                prompt: "How did the match go?",
                options: MatchResult.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedResult)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedResult) }

        case .score:
            ScoreBuilderView(scoreLines: $viewModel.scoreLines)

        case .format:
            DebriefQuestionView(
                prompt: "What were you playing?",
                options: MatchFormat.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedFormat)
            ) {
                viewModel.selectedProblems.removeAll()
                viewModel.selectedImprovementAreas.removeAll()
                viewModel.selectedWhatWorked = nil
                // Clear second opponent when switching away from doubles
                if $0 == .singles {
                    viewModel.secondOpponentName = ""
                    viewModel.secondSelectedOpponentId = nil
                }
                viewModel.selectAndAdvance($0, binding: \.selectedFormat)
            }

        case .opponent:
            OpponentInputView(
                opponentName: $viewModel.opponentName,
                selectedOpponentId: $viewModel.selectedOpponentId,
                secondOpponentName: $viewModel.secondOpponentName,
                secondSelectedOpponentId: $viewModel.secondSelectedOpponentId,
                opponents: sortedOpponents,
                isDoubles: viewModel.isDoubles
            )

        case .biggestProblems:
            DebriefQuestionView(
                prompt: "What hurt you most?",
                options: viewModel.availableProblems,
                icon: \.icon,
                selection: viewModel.selectedProblems,
                multiSelect: true,
                maxSelections: 2
            ) { viewModel.toggleProblem($0) }

        case .whatWorked:
            DebriefQuestionView(
                prompt: "What worked well?",
                options: WhatWorked.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedWhatWorked)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedWhatWorked) }

        case .improvementAreas:
            DebriefQuestionView(
                prompt: "What could have been cleaner?",
                options: ImprovementArea.allCases,
                icon: \.icon,
                selection: viewModel.selectedImprovementAreas,
                multiSelect: true,
                maxSelections: 2
            ) { viewModel.toggleImprovementArea($0) }

        case .pattern:
            DebriefQuestionView(
                prompt: "What happened most points?",
                options: MatchPattern.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedPattern)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedPattern) }

        case .opponentLevel:
            DebriefQuestionView(
                prompt: "How did they compare to you?",
                options: OpponentLevel.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedOpponentLevel)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedOpponentLevel) }

        case .context:
            DebriefContextView(
                selectedContexts: $viewModel.selectedContexts,
                contextNote: $viewModel.contextNote
            )
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: AppSpacing.md) {
            if !viewModel.isFirstStep {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goBack()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AppFont.headline())
                    .frame(maxWidth: viewModel.showsContinueButton ? nil : .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .padding(.horizontal, viewModel.showsContinueButton ? AppSpacing.lg : 0)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            if viewModel.showsContinueButton {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goNext()
                    }
                } label: {
                    Text(viewModel.isLastStep ? "Generate Debrief" : "Continue")
                        .font(AppFont.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(viewModel.canContinue ? AppColors.primary : AppColors.primary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canContinue)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
    }

    // MARK: - Generating State

    private var generatingView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Analyzing your match...")
                .font(AppFont.headline())
                .foregroundStyle(AppColors.secondaryLabel)
            Spacer()
        }
    }

    // MARK: - Error State

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.secondaryLabel)
            Text(message)
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            PrimaryButton("Try Again", icon: "arrow.clockwise") {
                viewModel.retry()
            }
            .padding(.horizontal, AppSpacing.lg)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func setFrom<T: Hashable>(_ value: T?) -> Set<T> {
        guard let value else { return [] }
        return [value]
    }

    /// Opponents sorted by most recent match first
    private var sortedOpponents: [Opponent] {
        let matchDates: [UUID: Date] = Dictionary(
            allMatches.flatMap { match in
                match.opponentIds.map { ($0, match.date) }
            },
            uniquingKeysWith: { a, b in max(a, b) }
        )

        return allOpponents.sorted { a, b in
            let dateA = matchDates[a.id] ?? a.createdAt
            let dateB = matchDates[b.id] ?? b.createdAt
            return dateA > dateB
        }
    }
}

#Preview {
    DebriefFlowView()
        .modelContainer(for: [Match.self, Opponent.self], inMemory: true)
}
