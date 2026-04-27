import SwiftUI

struct DebriefSummaryView: View {
    let result: DebriefResult
    var opponentHistoryNames: [String] = []
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.primary)

                    Text("Your Debrief")
                        .font(AppFont.largeTitle())

                    if !opponentHistoryNames.isEmpty {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption2)
                            Text("Includes history vs \(opponentHistoryNames.joined(separator: " & "))")
                                .font(AppFont.caption())
                        }
                        .foregroundStyle(AppColors.secondaryLabel)
                    }
                }
                .padding(.top, AppSpacing.md)

                // Primary Issue
                summaryCard(
                    label: "Primary Issue",
                    icon: "target",
                    content: result.primaryIssue
                )

                // Explanation
                summaryCard(
                    label: "What Happened",
                    icon: "magnifyingglass",
                    content: result.explanation
                )

                // Next Match Adjustment
                summaryCard(
                    label: "Next Match",
                    icon: "arrow.right.circle.fill",
                    content: result.nextMatchAdjustment
                )

                // Save button
                PrimaryButton("Save & Close", icon: "checkmark") {
                    onSave()
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private func summaryCard(label: String, icon: String, content: String) -> some View {
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
}

#Preview {
    NavigationStack {
        DebriefSummaryView(
            result: DebriefResult(
                primaryIssue: "Patience collapsed in long rallies",
                explanation: "You didn't lose on skill\u{2014}you lost on patience. In long rallies against same-level opponents, unforced errors become the deciding factor.",
                nextMatchAdjustment: "Next match, aim to extend rallies by one extra shot before going aggressive."
            )
        ) { }
    }
}
