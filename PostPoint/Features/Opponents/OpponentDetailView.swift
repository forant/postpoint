import SwiftUI

struct OpponentDetailView: View {
    let opponent: Opponent
    let matches: [Match]
    @State private var showingScout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection
                scoutingSection
                statsSection
                if let latestAdjustment = latestNextMatchAdjustment {
                    latestAdjustmentSection(latestAdjustment)
                }
                matchesSection
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
        }
        .navigationTitle(opponent.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingScout = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingScout) {
            ScoutOpponentView(existingOpponent: opponent)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(opponent.displayName)
                .font(AppFont.largeTitle())

            HStack(spacing: AppSpacing.md) {
                if let record = record {
                    statPill(record, label: "Record")
                }
                statPill("\(matches.count)", label: matches.count == 1 ? "Match" : "Matches")
                if let lastDate = matches.first?.date {
                    statPill(lastDate.formatted(.dateTime.month(.abbreviated).day()), label: "Last Played")
                }
            }
        }
    }

    private func statPill(_ value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppFont.headline())
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Scouting Notes

    @ViewBuilder
    private var scoutingSection: some View {
        if let notes = opponent.scoutingNotes, !notes.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "note.text")
                        .foregroundStyle(AppColors.primary)
                    Text("Scouting Notes")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.secondaryLabel)
                        .textCase(.uppercase)
                }

                WrappingHStack(spacing: AppSpacing.sm) {
                    ForEach(scoutingPills(from: notes), id: \.text) { pill in
                        scoutingPill(pill.text, icon: pill.icon)
                    }
                }

                if let note = notes.note, !note.isEmpty {
                    Text(note)
                        .font(AppFont.body())
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            Button {
                showingScout = true
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(AppColors.primary)
                    Text("Add scouting notes")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private func scoutingPill(_ text: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(AppFont.caption())
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.primary.opacity(0.1))
        .foregroundStyle(AppColors.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats

    private var statsSection: some View {
        Group {
            if wins + losses > 0 {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Record Breakdown")
                        .font(AppFont.title())

                    HStack(spacing: AppSpacing.lg) {
                        VStack {
                            Text("\(wins)")
                                .font(AppFont.largeTitle())
                                .foregroundStyle(AppColors.primary)
                            Text("Wins")
                                .font(AppFont.caption())
                                .foregroundStyle(AppColors.secondaryLabel)
                        }
                        VStack {
                            Text("\(losses)")
                                .font(AppFont.largeTitle())
                                .foregroundStyle(.red)
                            Text("Losses")
                                .font(AppFont.caption())
                                .foregroundStyle(AppColors.secondaryLabel)
                        }
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Latest Adjustment

    private func latestAdjustmentSection(_ adjustment: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(AppColors.primary)
                Text("Latest Adjustment")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .textCase(.uppercase)
            }

            Text(adjustment)
                .font(AppFont.body())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Matches List

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Match History")
                .font(AppFont.title())

            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(matches) { match in
                    NavigationLink(value: match.id) {
                        MatchRowView(match: match)
                    }
                    .buttonStyle(.plain)
                    if match.id != matches.last?.id {
                        Divider()
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { matchID in
            if let match = matches.first(where: { $0.id == matchID }) {
                MatchDetailView(match: match)
            }
        }
    }

    // MARK: - Helpers

    private var wins: Int { matches.filter(\.isWin).count }
    private var losses: Int { matches.filter { !$0.isWin && $0.hasDebrief }.count }

    private var record: String? {
        guard wins + losses > 0 else { return nil }
        return "\(wins)\u{2013}\(losses)"
    }

    private var latestNextMatchAdjustment: String? {
        matches.first(where: { $0.hasDebrief })?.nextMatchAdjustment
    }

    private struct PillData: Hashable {
        let text: String
        let icon: String
    }

    private func scoutingPills(from notes: OpponentScoutingNotes) -> [PillData] {
        var pills: [PillData] = []
        if let style = notes.style { pills.append(PillData(text: style.rawValue, icon: "figure.tennis")) }
        if let weapon = notes.weapon { pills.append(PillData(text: weapon.rawValue, icon: "bolt.fill")) }
        if let weakness = notes.weakness { pills.append(PillData(text: weakness.rawValue, icon: "target")) }
        if let tendency = notes.tendency { pills.append(PillData(text: tendency.rawValue, icon: "arrow.triangle.branch")) }
        return pills
    }
}
