import SwiftUI

struct MatchDetailView: View {
    let match: Match

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                matchInfoSection
                if let input = match.debriefInput {
                    debriefInputSection(input)
                }
                if let input = match.debriefInput, input.hasContext {
                    contextSection(input)
                }
                if let result = match.debriefResult {
                    debriefResultSection(result)
                }
                if match.debriefInput == nil {
                    noDebriefPlaceholder
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
        }
        .navigationTitle("Match Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Match Info

    private var matchInfoSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header with sport icon and opponent
            HStack(spacing: AppSpacing.md) {
                Image(systemName: match.sport.icon)
                    .font(.title2)
                    .foregroundStyle(sportColor)
                    .frame(width: 48, height: 48)
                    .background(sportColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(match.displayOpponentName)
                        .font(AppFont.title())
                    Text(match.date, format: .dateTime.weekday(.wide).month(.abbreviated).day().year().hour().minute())
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }

            // Quick stats row
            HStack(spacing: AppSpacing.md) {
                infoPill(match.sport.rawValue, icon: match.sport.icon)
                if let result = match.debriefInput?.result {
                    infoPill(result.rawValue, icon: result.icon)
                }
                if let score = match.debriefInput?.scoreDisplay {
                    infoPill(score, icon: "number")
                }
            }
        }
    }

    private func infoPill(_ text: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(AppFont.caption())
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.secondaryBackground)
        .clipShape(Capsule())
    }

    // MARK: - Debrief Inputs

    private func debriefInputSection(_ input: DebriefInput) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Match Details")

            detailCard {
                detailRow("Format", value: input.matchFormat.rawValue, icon: input.matchFormat.icon)
                Divider()
                detailRow("Pattern", value: input.matchPattern.rawValue, icon: input.matchPattern.icon)
                Divider()
                detailRow("Opponent Level", value: input.opponentLevel.rawValue, icon: input.opponentLevel.icon)

                if !input.biggestProblems.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        detailLabel("Biggest Problems", icon: "exclamationmark.triangle")
                        ForEach(input.biggestProblems) { problem in
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: problem.icon)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 20)
                                Text(problem.rawValue)
                                    .font(AppFont.body())
                            }
                        }
                    }
                }

                if let whatWorked = input.whatWorked {
                    Divider()
                    detailRow("What Worked", value: whatWorked.rawValue, icon: whatWorked.icon)
                }

                if let areas = input.improvementAreas, !areas.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        detailLabel("Areas to Improve", icon: "arrow.up.circle")
                        ForEach(areas) { area in
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: area.icon)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 20)
                                Text(area.rawValue)
                                    .font(AppFont.body())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Context

    private func contextSection(_ input: DebriefInput) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Context")

            detailCard {
                if !input.notableContexts.isEmpty {
                    FlowLayout(spacing: AppSpacing.sm) {
                        ForEach(input.notableContexts) { context in
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: context.icon)
                                    .font(.caption)
                                Text(context.rawValue)
                                    .font(AppFont.subheadline())
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.primary.opacity(0.1))
                            .foregroundStyle(AppColors.primary)
                            .clipShape(Capsule())
                        }
                    }
                }

                if let note = input.contextNote, !note.isEmpty {
                    if !input.notableContexts.isEmpty {
                        Divider()
                    }
                    Text(note)
                        .font(AppFont.body())
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
        }
    }

    // MARK: - Debrief Result

    private func debriefResultSection(_ result: DebriefResult) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            sectionHeader("Debrief")

            resultCard(
                label: "Primary Issue",
                icon: "target",
                content: result.primaryIssue
            )

            resultCard(
                label: "What Happened",
                icon: "magnifyingglass",
                content: result.explanation
            )

            resultCard(
                label: "Next Match",
                icon: "arrow.right.circle.fill",
                content: result.nextMatchAdjustment
            )
        }
    }

    // MARK: - No Debrief Placeholder

    private var noDebriefPlaceholder: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.tertiaryLabel)
            Text("No debrief for this match.")
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)

            if !match.notes.isEmpty {
                Text(match.notes)
                    .font(AppFont.body())
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFont.title())
            .padding(.top, AppSpacing.xs)
    }

    private func detailCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            content()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func detailRow(_ label: String, value: String, icon: String) -> some View {
        HStack {
            detailLabel(label, icon: icon)
            Spacer()
            Text(value)
                .font(AppFont.body())
        }
    }

    private func detailLabel(_ label: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
            Text(label)
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)
        }
    }

    private func resultCard(label: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                Text(label)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .textCase(.uppercase)
            }

            Text(content)
                .font(AppFont.body())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var sportColor: Color {
        switch match.sport {
        case .tennis: return AppColors.tennis
        case .pickleball: return AppColors.pickleball
        case .padel: return AppColors.padel
        }
    }
}
