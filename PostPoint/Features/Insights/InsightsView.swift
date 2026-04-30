import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var showingDebrief = false

    private var debriefedMatches: [Match] {
        matches.filter { $0.debriefInput != nil }
    }

    var body: some View {
        NavigationStack {
            Group {
                if debriefedMatches.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            overallRecordCard
                            last10Card
                            trendCard
                            closeMatchCard
                            focusAreasCard
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationTitle("Insights")
            .fullScreenCover(isPresented: $showingDebrief) {
                DebriefFlowView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.tertiaryLabel)

            VStack(spacing: AppSpacing.sm) {
                Text("Your insights will build as you play")
                    .font(AppFont.title())
                    .multilineTextAlignment(.center)

                Text("Debrief a few matches and PostPoint will start showing your record, recent trends, and patterns to focus on.")
                    .font(AppFont.body())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            PrimaryButton("Start a Debrief", icon: "plus.circle.fill") {
                showingDebrief = true
            }
            .padding(.horizontal, AppSpacing.lg)
            Spacer()
        }
    }

    // MARK: - Overall Record

    private var overallRecordCard: some View {
        let wins = debriefedMatches.filter(\.isWin).count
        let losses = debriefedMatches.count - wins
        let pct = debriefedMatches.isEmpty ? 0 : Int(Double(wins) / Double(debriefedMatches.count) * 100)

        return insightCard(title: "Overall Record", icon: "trophy") {
            HStack(spacing: AppSpacing.xl) {
                statBlock(value: "\(debriefedMatches.count)", label: "Matches")
                statBlock(value: "\(wins)", label: "Wins", color: AppColors.primary)
                statBlock(value: "\(losses)", label: "Losses", color: .red)
                statBlock(value: "\(pct)%", label: "Win %")
            }
        }
    }

    // MARK: - Last 10

    private var last10Card: some View {
        let recent = Array(debriefedMatches.prefix(10))
        let wins = recent.filter(\.isWin).count
        let losses = recent.count - wins
        let pct = recent.isEmpty ? 0 : Int(Double(wins) / Double(recent.count) * 100)

        return insightCard(title: "Last \(recent.count) Matches", icon: "clock") {
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.xl) {
                    statBlock(value: "\(wins)–\(losses)", label: "Record")
                    statBlock(value: "\(pct)%", label: "Win %")
                }

                // Result pills row (newest first)
                HStack(spacing: AppSpacing.xs) {
                    ForEach(Array(recent.enumerated()), id: \.offset) { index, match in
                        resultPill(isWin: match.isWin, isNewest: index == 0)
                    }
                }
            }
        }
    }

    private func resultPill(isWin: Bool, isNewest: Bool) -> some View {
        Text(isWin ? "W" : "L")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(isWin ? AppColors.primary : Color.red)
            .clipShape(Circle())
            .overlay {
                if isNewest {
                    Circle()
                        .stroke(AppColors.label, lineWidth: 2)
                }
            }
    }

    // MARK: - Trend

    @ViewBuilder
    private var trendCard: some View {
        let trends = buildTrends()
        if !trends.isEmpty {
            insightCard(title: "Recent Trends", icon: "arrow.up.right") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(trends, id: \.self) { trend in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(trend)
                                .font(AppFont.body())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Close Matches

    @ViewBuilder
    private var closeMatchCard: some View {
        let closeMatches = debriefedMatches.filter { isCloseMatch($0) }
        if closeMatches.count >= 2 {
            let wins = closeMatches.filter(\.isWin).count
            let losses = closeMatches.count - wins

            insightCard(title: "Close Matches", icon: "equal.circle") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.xl) {
                        statBlock(value: "\(wins)–\(losses)", label: "Record")
                        statBlock(value: "\(closeMatches.count)", label: "Total")
                    }

                    if wins < losses {
                        Text("Close matches have been a challenge recently.")
                            .font(AppFont.caption())
                            .foregroundStyle(AppColors.secondaryLabel)
                    } else if wins > losses {
                        Text("You're winning the tight ones.")
                            .font(AppFont.caption())
                            .foregroundStyle(AppColors.secondaryLabel)
                    }
                }
            }
        }
    }

    // MARK: - Focus Areas

    @ViewBuilder
    private var focusAreasCard: some View {
        let adjustments = debriefedMatches
            .prefix(3)
            .compactMap { $0.debriefResult?.nextMatchAdjustment }

        if !adjustments.isEmpty {
            insightCard(title: "Recent Focus Areas", icon: "target") {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(Array(adjustments.enumerated()), id: \.offset) { _, adjustment in
                        Text(adjustment)
                            .font(AppFont.body())
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(AppSpacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func insightCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                Text(title)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .textCase(.uppercase)
            }

            content()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statBlock(value: String, label: String, color: Color = AppColors.label) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(AppColors.secondaryLabel)
        }
    }

    // MARK: - Trend Logic

    private func buildTrends() -> [String] {
        var trends: [String] = []
        let recent5 = Array(debriefedMatches.prefix(5))
        guard recent5.count >= 3 else { return trends }

        let wins5 = recent5.filter(\.isWin).count
        let losses5 = recent5.count - wins5

        if wins5 >= 4 {
            trends.append("You've won \(wins5) of your last \(recent5.count) matches.")
        } else if losses5 >= 4 {
            trends.append("You're \(wins5)–\(losses5) in your last \(recent5.count) matches.")
        } else {
            trends.append("You've won \(wins5) of your last \(recent5.count) matches.")
        }

        // Check if trending up or down (compare first half vs second half of last 6+)
        let recent6 = Array(debriefedMatches.prefix(6))
        if recent6.count >= 6 {
            let recentHalf = recent6.prefix(3).filter(\.isWin).count
            let olderHalf = recent6.suffix(3).filter(\.isWin).count
            if recentHalf > olderHalf {
                trends.append("Your recent results are trending up.")
            } else if recentHalf < olderHalf {
                trends.append("Your recent results have dipped — a good time to focus on patterns.")
            }
        }

        // Close match trend
        let closeRecent = recent5.filter { isCloseMatch($0) }
        if closeRecent.count >= 2 {
            let closeWins = closeRecent.filter(\.isWin).count
            let closeLosses = closeRecent.count - closeWins
            if closeLosses > closeWins {
                trends.append("Close matches have been a challenge — \(closeWins)–\(closeLosses) recently.")
            }
        }

        return Array(trends.prefix(3))
    }

    // MARK: - Close Match Detection

    private func isCloseMatch(_ match: Match) -> Bool {
        // Check result type first
        guard let result = match.debriefInput?.result else { return false }
        if result == .wonClose || result == .lostClose { return true }

        // Check score data: went to deciding set or tight final set
        guard let lines = match.debriefInput?.scoreLines.filter({ $0.hasScore }),
              lines.count >= 2 else { return false }

        // Deciding set (3rd set in best-of-3)
        if lines.count >= 3 { return true }

        // Tight final set (within 2 games)
        if let last = lines.last {
            let diff = abs(last.playerScore - last.opponentScore)
            if diff <= 2 { return true }
        }

        return false
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: Match.self, inMemory: true)
}
