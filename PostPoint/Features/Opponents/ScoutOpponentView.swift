import SwiftUI
import SwiftData

struct ScoutOpponentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Opponent.createdAt, order: .reverse) private var allOpponents: [Opponent]

    /// If editing an existing opponent, pass it in
    var existingOpponent: Opponent?

    @State private var step = 0
    @State private var opponentName = ""
    @State private var selectedOpponentId: UUID?
    @State private var selectedStyle: OpponentStyle?
    @State private var selectedWeapon: OpponentWeapon?
    @State private var selectedWeakness: OpponentWeakness?
    @State private var selectedTendency: OpponentTendency?
    @State private var note = ""
    @State private var matchDate: Date?
    @State private var showDatePicker = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1) / 2.0)
                    .tint(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)

                ScrollView {
                    if step == 0 && existingOpponent == nil {
                        nameStep
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.lg)
                    } else {
                        scoutingStep
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.lg)
                    }
                }

                bottomBar
            }
            .navigationTitle("Scout Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let existing = existingOpponent {
                    opponentName = existing.displayName
                    selectedOpponentId = existing.id
                    step = 1
                    // Pre-fill existing scouting notes
                    if let notes = existing.scoutingNotes {
                        selectedStyle = notes.style
                        selectedWeapon = notes.weapon
                        selectedWeakness = notes.weakness
                        selectedTendency = notes.tendency
                        note = notes.note ?? ""
                    }
                }
            }
            .overlay {
                if showConfirmation {
                    confirmationOverlay
                }
            }
        }
    }

    // MARK: - Step 1: Name

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Who are you scouting?")
                .font(AppFont.title())

            TextField("Opponent name", text: $opponentName)
                .font(AppFont.headline())
                .padding(AppSpacing.md)
                .background(AppColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .submitLabel(.continue)
                .onSubmit {
                    if canContinue { advanceToScouting() }
                }

            if !filteredSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Existing opponents")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.tertiaryLabel)

                    ForEach(filteredSuggestions) { opponent in
                        Button {
                            opponentName = opponent.displayName
                            selectedOpponentId = opponent.id
                            advanceToScouting()
                        } label: {
                            HStack {
                                Text(opponent.displayName)
                                    .font(AppFont.body())
                                Spacer()
                                if opponent.scoutingNotes != nil {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryLabel)
                                }
                            }
                            .padding(AppSpacing.sm)
                            .background(AppColors.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Scouting Chips

    private var scoutingStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Quick notes on \(opponentName)")
                .font(AppFont.title())

            chipSection(title: "What's their style?", options: OpponentStyle.allCases, selected: $selectedStyle)

            chipSection(title: "What do they do well?", options: OpponentWeapon.allCases, selected: $selectedWeapon)

            chipSection(title: "What can you attack?", options: OpponentWeakness.allCases, selected: $selectedWeakness)

            chipSection(title: "Any tendencies to remember?", options: OpponentTendency.allCases, selected: $selectedTendency)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Anything else you notice?")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColors.secondaryLabel)

                TextField("Optional notes", text: $note, axis: .vertical)
                    .font(AppFont.body())
                    .lineLimit(2...4)
                    .padding(AppSpacing.md)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Optional match date
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Playing them soon?")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColors.secondaryLabel)

                if let date = matchDate {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppColors.primary)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(AppFont.body())
                        Spacer()
                        Button {
                            matchDate = nil
                            showDatePicker = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.tertiaryLabel)
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if showDatePicker {
                    DatePicker(
                        "Match date",
                        selection: Binding(
                            get: { matchDate ?? Date() },
                            set: { matchDate = $0 }
                        ),
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppColors.primary)
                } else {
                    Button {
                        matchDate = Date()
                        showDatePicker = true
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(AppColors.primary)
                            Text("Set match date")
                                .font(AppFont.subheadline())
                                .foregroundStyle(AppColors.primary)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func chipSection<T: RawRepresentable & Identifiable & CaseIterable>(
        title: String,
        options: [T],
        selected: Binding<T?>
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)

            WrappingHStack(spacing: AppSpacing.sm) {
                ForEach(options) { option in
                    ChipButton(
                        title: option.rawValue,
                        isSelected: selected.wrappedValue?.rawValue == option.rawValue
                    ) {
                        if selected.wrappedValue?.rawValue == option.rawValue {
                            selected.wrappedValue = nil
                        } else {
                            selected.wrappedValue = option
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: AppSpacing.md) {
            if step == 1 && existingOpponent == nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { step = 0 }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(AppFont.headline())
                    .padding(.vertical, AppSpacing.md)
                    .padding(.horizontal, AppSpacing.lg)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                if step == 0 {
                    advanceToScouting()
                } else {
                    saveAndDismiss()
                }
            } label: {
                Text(step == 0 ? "Continue" : "Save Notes")
                    .font(AppFont.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(canContinue ? AppColors.primary : AppColors.primary.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canContinue)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
    }

    // MARK: - Confirmation

    private var confirmationOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
            Text("Opponent notes saved")
                .font(AppFont.headline())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .task {
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        }
    }

    // MARK: - Logic

    private var canContinue: Bool {
        if step == 0 {
            return !opponentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true // scouting step is always saveable
    }

    private var filteredSuggestions: [Opponent] {
        let trimmed = opponentName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return allOpponents
            .filter { $0.normalizedName.contains(trimmed) }
            .prefix(5)
            .map { $0 }
    }

    private func advanceToScouting() {
        guard canContinue else { return }
        // Resolve opponent if selecting by name
        if selectedOpponentId == nil {
            let trimmed = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = Opponent.normalize(trimmed)
            if let existing = allOpponents.first(where: { $0.normalizedName == normalized }) {
                selectedOpponentId = existing.id
                // Pre-fill existing notes
                if let notes = existing.scoutingNotes {
                    selectedStyle = selectedStyle ?? notes.style
                    selectedWeapon = selectedWeapon ?? notes.weapon
                    selectedWeakness = selectedWeakness ?? notes.weakness
                    selectedTendency = selectedTendency ?? notes.tendency
                    if note.isEmpty { note = notes.note ?? "" }
                }
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) { step = 1 }
    }

    private func saveAndDismiss() {
        let trimmed = opponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let opponent: Opponent
        if let id = selectedOpponentId, let existing = allOpponents.first(where: { $0.id == id }) {
            opponent = existing
        } else {
            opponent = Opponent.findOrCreate(displayName: trimmed, in: modelContext)
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        opponent.scoutingNotes = OpponentScoutingNotes(
            style: selectedStyle,
            weapon: selectedWeapon,
            weakness: selectedWeakness,
            tendency: selectedTendency,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            updatedAt: Date()
        )

        try? modelContext.save()

        // If a match date was set, create/update a NextMatch
        if let date = matchDate {
            let nextMatch = NextMatch(
                scheduledDate: date,
                sport: .tennis,
                opponentName: opponent.displayName
            )
            NextMatchService.save(nextMatch)
        }

        AnalyticsService.track(.opponentScouted, properties: [
            "has_style": selectedStyle != nil,
            "has_weapon": selectedWeapon != nil,
            "has_weakness": selectedWeakness != nil,
            "has_tendency": selectedTendency != nil,
            "has_note": !trimmedNote.isEmpty,
            "has_match_date": matchDate != nil,
            "is_existing_opponent": selectedOpponentId != nil,
        ])

        withAnimation { showConfirmation = true }
    }
}

// MARK: - Chip Button

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.subheadline())
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.primary.opacity(0.15) : AppColors.secondaryBackground)
                .foregroundStyle(isSelected ? AppColors.primary : AppColors.label)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Flow Layout (wrapping chips)

struct WrappingHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    ScoutOpponentView()
        .modelContainer(for: [Opponent.self, Match.self], inMemory: true)
}
