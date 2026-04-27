import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: viewModel.progress)
                    .tint(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)

                Text("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .padding(.top, AppSpacing.sm)

                ScrollView {
                    currentStep
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)
                }

                navigationBar
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AnalyticsService.track(.onboardingStarted)
            }
            .onChange(of: viewModel.isComplete) {
                if viewModel.isComplete {
                    onComplete()
                }
            }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var currentStep: some View {
        switch viewModel.currentStep {
        case 0:
            nameStep
        case 1:
            ratingTypeStep
        case 2:
            ratingInputStep
        case 3:
            focusAreasStep
        case 4:
            biggestStruggleStep
        default:
            EmptyView()
        }
    }

    // MARK: - Step 1: Name

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What's your first name?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            Text("We'll use this to personalize your debriefs.")
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)

            TextField("First name", text: $viewModel.firstName)
                .font(AppFont.headline())
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .submitLabel(.continue)
                .onSubmit {
                    if viewModel.canContinue {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.goNext()
                        }
                    }
                }
        }
    }

    // MARK: - Step 2: Rating Type

    private var ratingTypeStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("How do you track your level?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            ForEach(RatingType.allCases) { type in
                DebriefOptionCard(
                    title: type.rawValue,
                    icon: type.icon,
                    isSelected: viewModel.selectedRatingType == type
                ) {
                    viewModel.selectAndAdvanceRatingType(type)
                }
            }
        }
    }

    // MARK: - Step 3: Rating Input

    @ViewBuilder
    private var ratingInputStep: some View {
        switch viewModel.selectedRatingType {
        case .utr:
            utrInputStep
        case .usta:
            ustaInputStep
        case .selfReported:
            selfReportedStep
        case .none:
            EmptyView()
        }
    }

    private var utrInputStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What's your UTR?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            Text("Enter a value between 1.0 and 16.5")
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)

            TextField("e.g. 6.5", text: $viewModel.utrValue)
                .font(AppFont.headline())
                .keyboardType(.decimalPad)
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var ustaInputStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What's your NTRP rating?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            ForEach(OnboardingViewModel.ustaLevels, id: \.self) { level in
                DebriefOptionCard(
                    title: level,
                    icon: "star.circle",
                    isSelected: viewModel.selectedUSTALevel == level
                ) {
                    viewModel.selectedUSTALevel = level
                }
            }
        }
    }

    private var selfReportedStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("How would you describe your level?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            ForEach(PlayerLevel.allCases) { level in
                DebriefOptionCard(
                    title: level.rawValue,
                    icon: level.icon,
                    isSelected: viewModel.selectedPlayerLevel == level
                ) {
                    viewModel.selectedPlayerLevel = level
                }
            }
        }
    }

    // MARK: - Step 4: Focus Areas

    private var focusAreasStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What are you trying to improve?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            Text("Pick up to 3 focus areas.")
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)

            ForEach(FocusArea.allCases) { area in
                DebriefOptionCard(
                    title: area.rawValue,
                    icon: area.icon,
                    isSelected: viewModel.selectedFocusAreas.contains(area)
                ) {
                    viewModel.toggleFocusArea(area)
                }
            }
        }
    }

    // MARK: - Step 5: Biggest Struggle

    private var biggestStruggleStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What frustrates you most in matches?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            Text("Optional — helps us tailor your debriefs.")
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)

            TextField("e.g. Dumping easy volleys into the net", text: $viewModel.biggestStruggleText, axis: .vertical)
                .font(AppFont.body())
                .lineLimit(3...6)
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Ideas:")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.tertiaryLabel)

                ForEach(biggestStruggleExamples, id: \.self) { example in
                    Button {
                        viewModel.biggestStruggleText = example
                    } label: {
                        Text(example)
                            .font(AppFont.caption())
                            .foregroundStyle(AppColors.secondaryLabel)
                            .padding(.vertical, AppSpacing.xs)
                            .padding(.horizontal, AppSpacing.sm)
                            .background(AppColors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var biggestStruggleExamples: [String] {
        [
            "Dumping easy volleys into the net",
            "Mental collapse when serving for the match",
            "Lack of focus",
            "My weak second serve",
        ]
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
                    Text(viewModel.isLastStep ? "Finish" : "Continue")
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
}

#Preview {
    OnboardingView { }
}
