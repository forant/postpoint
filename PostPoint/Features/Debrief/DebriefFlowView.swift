import SwiftUI
import SwiftData

struct DebriefFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DebriefFlowViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isGenerating {
                    generatingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let result = viewModel.debriefResult {
                    DebriefSummaryView(result: result) {
                        viewModel.saveMatch(to: modelContext, sport: .tennis)
                        dismiss()
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
        switch viewModel.currentStep {
        case 0:
            DebriefQuestionView(
                prompt: "How did the match go?",
                options: MatchResult.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedResult)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedResult) }

        case 1:
            ScoreBuilderView(scoreLines: $viewModel.scoreLines)

        case 2:
            DebriefQuestionView(
                prompt: "What were you playing?",
                options: MatchFormat.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedFormat)
            ) {
                viewModel.selectedProblems.removeAll()
                viewModel.selectAndAdvance($0, binding: \.selectedFormat)
            }

        case 3:
            DebriefQuestionView(
                prompt: "What hurt you most?",
                options: viewModel.availableProblems,
                icon: \.icon,
                selection: viewModel.selectedProblems,
                multiSelect: true,
                maxSelections: 2
            ) { viewModel.toggleProblem($0) }

        case 4:
            DebriefQuestionView(
                prompt: "What happened most points?",
                options: MatchPattern.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedPattern)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedPattern) }

        case 5:
            DebriefQuestionView(
                prompt: "How did they compare to you?",
                options: OpponentLevel.allCases,
                icon: \.icon,
                selection: setFrom(viewModel.selectedOpponentLevel)
            ) { viewModel.selectAndAdvance($0, binding: \.selectedOpponentLevel) }

        case 6:
            DebriefContextView(
                selectedContexts: $viewModel.selectedContexts,
                contextNote: $viewModel.contextNote
            )

        default:
            EmptyView()
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
}

#Preview {
    DebriefFlowView()
        .modelContainer(for: Match.self, inMemory: true)
}
