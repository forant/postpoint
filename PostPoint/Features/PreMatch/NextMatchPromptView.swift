import SwiftUI

/// Lightweight prompt for setting the user's next match.
/// Used in onboarding (as a step) and after debrief completion.
struct NextMatchPromptView: View {
    @State private var scheduledDate: Date = defaultDate
    @State private var opponentName: String = ""
    @State private var hasExistingMatch = false
    @State private var existingMatch: NextMatch?

    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(hasExistingMatch ? "Your next match" : "When's your next match?")
                .font(AppFont.title())
                .foregroundStyle(AppColors.label)

            Text("PostPoint can send you a quick pre-match focus on game day.")
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)

            if hasExistingMatch, let existing = existingMatch {
                existingMatchCard(existing)
            } else {
                inputFields
            }

            // Action buttons
            VStack(spacing: AppSpacing.sm) {
                if hasExistingMatch {
                    PrimaryButton("Keep it", icon: "checkmark") {
                        onDone()
                    }

                    Button {
                        hasExistingMatch = false
                    } label: {
                        Text("Update it")
                            .font(AppFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    PrimaryButton("Set next match", icon: "calendar") {
                        saveAndDismiss()
                    }
                }

                Button {
                    AnalyticsService.track(.nextMatchSkipped)
                    onDone()
                } label: {
                    Text("I'm not sure yet")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.secondaryLabel)
                        .padding(.vertical, AppSpacing.sm)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, AppSpacing.sm)
        }
        .onAppear {
            if let existing = NextMatch.load(), existing.isFutureMatch {
                existingMatch = existing
                hasExistingMatch = true
                scheduledDate = existing.scheduledDate
                opponentName = existing.opponentName ?? ""
            }
        }
    }

    // MARK: - Input Fields

    private var inputFields: some View {
        VStack(spacing: AppSpacing.md) {
            DatePicker(
                "Match date",
                selection: $scheduledDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppColors.primary)

            TextField("Opponent (optional)", text: $opponentName)
                .font(AppFont.body())
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Existing Match Card

    private func existingMatchCard(_ match: NextMatch) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(match.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                    .font(AppFont.headline())
                if let name = match.opponentName, !name.isEmpty {
                    Text("vs \(name)")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        let trimmedName = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)

        let match = NextMatch(
            scheduledDate: scheduledDate,
            sport: .tennis,
            opponentName: trimmedName.isEmpty ? nil : trimmedName
        )

        NextMatchService.save(match)
        onDone()
    }

    private static var defaultDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
}

#Preview {
    NextMatchPromptView { }
}
