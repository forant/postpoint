import SwiftUI

struct ScoreBuilderView: View {
    @Binding var scoreLines: [ScoreLine]

    private let maxSets = 5

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("What was the score?")
                .font(AppFont.largeTitle())

            Text("Optional \u{2014} tap +/- to enter scores")
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)

            VStack(spacing: AppSpacing.md) {
                ForEach(Array(scoreLines.enumerated()), id: \.element.id) { index, _ in
                    ScoreLineRow(
                        label: scoreLines.count > 1 ? "Set \(index + 1)" : "Score",
                        line: $scoreLines[index],
                        canDelete: scoreLines.count > 1
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scoreLines.remove(at: index)
                        }
                    }
                }
            }

            if scoreLines.count < maxSets {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scoreLines.append(ScoreLine())
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add set/game")
                    }
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColors.primary)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
    }
}

// MARK: - Score Line Row

private struct ScoreLineRow: View {
    let label: String
    @Binding var line: ScoreLine
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(label)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .textCase(.uppercase)

                Spacer()

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.tertiaryLabel)
                    }
                }
            }

            HStack(spacing: AppSpacing.md) {
                ScoreCounter(label: "You", value: $line.playerScore)
                
                Text("\u{2013}")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.tertiaryLabel)

                ScoreCounter(label: "Opp", value: $line.opponentScore)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Score Counter

private struct ScoreCounter: View {
    let label: String
    @Binding var value: Int

    private let maxScore = 30

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(AppColors.tertiaryLabel)

            HStack(spacing: AppSpacing.sm) {
                // Minus button
                Button {
                    if value > 0 { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value > 0 ? AppColors.primary : AppColors.tertiaryLabel)
                }
                .disabled(value <= 0)

                // Score display
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .frame(minWidth: 44)
                    .contentTransition(.numericText())

                // Plus button
                Button {
                    if value < maxScore { value += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(value < maxScore ? AppColors.primary : AppColors.tertiaryLabel)
                }
                .disabled(value >= maxScore)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var lines = [ScoreLine()]
    ScoreBuilderView(scoreLines: $lines)
        .padding()
}
