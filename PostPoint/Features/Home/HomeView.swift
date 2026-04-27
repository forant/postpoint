import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    debriefButton
                    recentMatchesSection
                    progressTeaser
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
            .navigationTitle("PostPoint")
            .fullScreenCover(isPresented: $viewModel.showingDebrief) {
                DebriefFlowView()
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
                        MatchRowView(match: match)
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
    HomeView()
        .modelContainer(for: Match.self, inMemory: true)
}
