import SwiftUI

struct OpponentInputView: View {
    @Binding var opponentName: String
    @Binding var selectedOpponentId: UUID?
    @Binding var secondOpponentName: String
    @Binding var secondSelectedOpponentId: UUID?
    let opponents: [Opponent]
    let isDoubles: Bool
    @FocusState private var focusedField: Field?

    private enum Field { case first, second }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(isDoubles ? "Who did you play against?" : "Who did you play?")
                .font(AppFont.largeTitle())
                .fixedSize(horizontal: false, vertical: true)

            Text("Optional \u{2014} helps track patterns over time.")
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)

            // Primary opponent
            opponentField(
                label: isDoubles ? "Opponent 1" : "Opponent name",
                name: $opponentName,
                selectedId: $selectedOpponentId,
                field: .first
            )

            // Second opponent (doubles only)
            if isDoubles {
                opponentField(
                    label: "Opponent 2",
                    name: $secondOpponentName,
                    selectedId: $secondSelectedOpponentId,
                    field: .second
                )
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(activeSuggestionLabel)
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.secondaryLabel)

                    FlowLayout(spacing: AppSpacing.sm) {
                        ForEach(suggestions) { opponent in
                            Button {
                                selectSuggestion(opponent)
                            } label: {
                                let isSelected = selectedOpponentId == opponent.id || secondSelectedOpponentId == opponent.id
                                Text(opponent.displayName)
                                    .font(AppFont.subheadline())
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(isSelected ? AppColors.primary.opacity(0.15) : AppColors.secondaryBackground)
                                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.label)
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 1.5)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Opponent Field

    private func opponentField(
        label: String,
        name: Binding<String>,
        selectedId: Binding<UUID?>,
        field: Field
    ) -> some View {
        TextField(label, text: name)
            .font(AppFont.body())
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .focused($focusedField, equals: field)
            .onChange(of: name.wrappedValue) {
                // Clear selection if user edits after picking
                if let selected = selectedId.wrappedValue,
                   let opponent = opponents.first(where: { $0.id == selected }),
                   opponent.displayName != name.wrappedValue {
                    selectedId.wrappedValue = nil
                }
            }
    }

    // MARK: - Suggestions

    private var activeSuggestionLabel: String {
        let isTyping = focusedField != nil
        let activeText = focusedField == .second ? secondOpponentName : opponentName
        return isTyping && !activeText.isEmpty ? "Suggestions" : "Recent"
    }

    private func selectSuggestion(_ opponent: Opponent) {
        if focusedField == .second {
            secondOpponentName = opponent.displayName
            secondSelectedOpponentId = opponent.id
        } else {
            opponentName = opponent.displayName
            selectedOpponentId = opponent.id
        }
        focusedField = nil
    }

    /// Shows filtered matches when typing, or recent opponents when idle
    private var suggestions: [Opponent] {
        let activeText: String
        if focusedField == .second {
            activeText = secondOpponentName
        } else {
            activeText = opponentName
        }

        let trimmed = activeText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmed.isEmpty {
            return Array(opponents.prefix(5))
        }

        return opponents.filter {
            $0.displayName.lowercased().contains(trimmed)
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var selectedId: UUID? = nil
    @Previewable @State var name2 = ""
    @Previewable @State var selectedId2: UUID? = nil
    OpponentInputView(
        opponentName: $name,
        selectedOpponentId: $selectedId,
        secondOpponentName: $name2,
        secondSelectedOpponentId: $selectedId2,
        opponents: [],
        isDoubles: true
    )
    .padding()
}
