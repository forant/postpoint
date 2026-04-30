import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var viewModel = HomeViewModel()
    @Binding var tabSelection: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    debriefButton

                    if viewModel.shouldShowPreMatchCard {
                        preMatchBriefCard
                    } else {
                        scoutOpponentTeaser
                    }

                    recentMatchesSection
                    progressTeaser
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
            .navigationTitle("PostPoint")
            .onAppear {
                viewModel.loadNextMatch()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                viewModel.loadNextMatch()
            }
            .onChange(of: tabSelection) { _, newTab in
                if newTab == 0 { viewModel.loadNextMatch() }
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PostPoint")
                        .font(.headline)
                        .onLongPressGesture {
                            UserDefaults.standard.removeObject(forKey: "PostPoint.playerProfile")
                            viewModel.showOnboardingResetAlert = true
                        }
                }
            }
            .alert("Onboarding Reset", isPresented: $viewModel.showOnboardingResetAlert) {
                Button("OK") { }
            } message: {
                Text("Restart the app to re-run onboarding.")
            }
            #endif
            .navigationDestination(for: UUID.self) { matchID in
                if let match = matches.first(where: { $0.id == matchID }) {
                    MatchDetailView(match: match)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingDebrief) {
                DebriefFlowView()
            }
            .fullScreenCover(isPresented: $viewModel.showingPreMatchBrief) {
                PreMatchBriefView()
            }
            .sheet(isPresented: $viewModel.showingScoutOpponent) {
                ScoutOpponentView()
            }
            .onChange(of: viewModel.showingScoutOpponent) { _, isShowing in
                if !isShowing { viewModel.loadNextMatch() }
            }
            .onChange(of: viewModel.showingDebrief) { _, isShowing in
                if !isShowing { viewModel.loadNextMatch() }
            }
        }
    }

    // MARK: - Primary CTA

    private var debriefButton: some View {
        PrimaryButton("Debrief a Match", icon: "plus.circle.fill") {
            viewModel.showingDebrief = true
        }
        .padding(.top, AppSpacing.sm)
    }

    // MARK: - Pre-Match Brief Card

    private var preMatchBriefCard: some View {
        Button {
            viewModel.showingPreMatchBrief = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    if let match = viewModel.nextMatch {
                        let isToday = Calendar.current.isDateInToday(match.scheduledDate)
                        Text(isToday ? "Match day" : "Match tomorrow")
                            .font(AppFont.headline())
                            .foregroundStyle(AppColors.label)

                        if let name = match.opponentName, !name.isEmpty {
                            Text("vs \(name) · View your pre-match focus")
                                .font(AppFont.caption())
                                .foregroundStyle(AppColors.secondaryLabel)
                        } else {
                            Text("View your pre-match focus")
                                .font(AppFont.caption())
                                .foregroundStyle(AppColors.secondaryLabel)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryLabel)
            }
            .padding(AppSpacing.md)
            .background(AppColors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scout Opponent Teaser

    private var scoutOpponentTeaser: some View {
        Button {
            viewModel.showingScoutOpponent = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(AppColors.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Playing someone soon?")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.label)
                    Text("Scout opponent & set match date")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColors.secondaryLabel)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.tertiaryLabel)
            }
            .padding(AppSpacing.md)
            .background(AppColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Matches

    private var recentMatchesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Recent Matches")
                .font(AppFont.title())

            if matches.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentMatches(matches)) { match in
                        NavigationLink(value: match.id) {
                            MatchRowView(match: match)
                        }
                        .buttonStyle(.plain)
                        if match.id != viewModel.recentMatches(matches).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "sportscourt")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.tertiaryLabel)
            Text("No matches yet.\nDebrief your first match.")
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }

    // MARK: - Progress Teaser

    private var progressTeaser: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .foregroundStyle(AppColors.primary)
            Text("You've logged **\(matches.count)** match\(matches.count == 1 ? "" : "es")")
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView(tabSelection: .constant(0))
        .modelContainer(for: Match.self, inMemory: true)
}
