import SwiftUI
import SwiftData

struct OpponentsView: View {
    @Query(sort: \Opponent.createdAt, order: .reverse) private var opponents: [Opponent]
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]

    var body: some View {
        NavigationStack {
            Group {
                if sortedOpponents.isEmpty {
                    ContentUnavailableView(
                        "No Opponents Yet",
                        systemImage: "person.2",
                        description: Text("Add one during your next debrief.")
                    )
                } else {
                    List(sortedOpponents) { opponent in
                        NavigationLink(value: opponent.id) {
                            OpponentRow(
                                opponent: opponent,
                                matches: matches.matches(against: opponent.id)
                            )
                        }
                    }
                    .navigationDestination(for: UUID.self) { opponentId in
                        if let opponent = opponents.first(where: { $0.id == opponentId }) {
                            OpponentDetailView(
                                opponent: opponent,
                                matches: matches.matches(against: opponent.id)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Opponents")
        }
    }

    /// Opponents sorted by most recent match first
    private var sortedOpponents: [Opponent] {
        let matchDates: [UUID: Date] = Dictionary(
            matches.flatMap { match in
                match.opponentIds.map { ($0, match.date) }
            },
            uniquingKeysWith: { a, b in max(a, b) }
        )

        return opponents.sorted { a, b in
            let dateA = matchDates[a.id] ?? a.createdAt
            let dateB = matchDates[b.id] ?? b.createdAt
            return dateA > dateB
        }
    }
}

// MARK: - Opponent Row

private struct OpponentRow: View {
    let opponent: Opponent
    let matches: [Match]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(opponent.displayName)
                    .font(AppFont.headline())

                if let lastDate = matches.first?.date {
                    Text(lastDate, format: .dateTime.month(.abbreviated).day().year())
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.tertiaryLabel)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                if let record = record {
                    Text(record)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColors.primary)
                }
                Text("\(matches.count) match\(matches.count == 1 ? "" : "es")")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var record: String? {
        let wins = matches.filter(\.isWin).count
        let losses = matches.filter { !$0.isWin && $0.debriefInput != nil }.count
        guard wins + losses > 0 else { return nil }
        return "\(wins)\u{2013}\(losses)"
    }
}

#Preview {
    OpponentsView()
        .modelContainer(for: [Match.self, Opponent.self], inMemory: true)
}
