import SwiftUI
import SwiftData

struct PreMatchBriefView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Match.date, order: .reverse) private var recentMatches: [Match]
    @Query private var allOpponents: [Opponent]

    @State private var bullets: [String] = []
    @State private var isLoading = true
    @State private var usedFallback = false

    private let service = PreMatchBriefService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                        .padding(.top, AppSpacing.md)

                    if isLoading {
                        loadingState
                    } else {
                        bulletsList
                    }

                    Spacer(minLength: AppSpacing.xl)

                    PrimaryButton("Got it", icon: "checkmark") {
                        dismiss()
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
            .navigationTitle("Pre-Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await loadBrief()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Image(systemName: "target")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.primary)

            Text("Today's Focus")
                .font(AppFont.largeTitle())

            if let nextMatch = NextMatch.load(), let name = nextMatch.opponentName, !name.isEmpty {
                Text("Before your match against \(name)")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColors.secondaryLabel)
            } else {
                Text("Before your match")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColors.secondaryLabel)
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .controlSize(.large)
            Text("Building your match focus...")
                .font(AppFont.subheadline())
                .foregroundStyle(AppColors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Bullets

    private var bulletsList: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                bulletCard(number: index + 1, text: bullet)
            }
        }
    }

    private func bulletCard(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text("\(number)")
                .font(AppFont.headline())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(AppColors.primary)
                .clipShape(Circle())

            Text(text)
                .font(AppFont.body())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Data Loading

    private func loadBrief() async {
        guard let nextMatch = NextMatch.load() else {
            showFallback()
            return
        }

        do {
            let brief = try await service.generate(
                nextMatch: nextMatch,
                recentMatches: Array(recentMatches.prefix(5)),
                opponents: allOpponents
            )
            bullets = brief.bullets
            isLoading = false

            AnalyticsService.track(.preMatchBriefGenerated, properties: [
                "sport": nextMatch.sport.rawValue,
                "has_opponent": nextMatch.opponentName != nil,
                "recent_debrief_count": min(recentMatches.count, 3),
            ])
        } catch {
            #if DEBUG
            print("[PreMatchBrief] Generation failed: \(error). Using fallback.")
            #endif
            showFallback()
            AnalyticsService.track(.preMatchBriefFailed, properties: [
                "error": error.localizedDescription,
            ])
        }

        AnalyticsService.track(.preMatchBriefViewed, properties: [
            "used_fallback": usedFallback,
        ])
    }

    private func showFallback() {
        bullets = PreMatchBriefService.fallbackBullets(profile: PlayerProfile.load())
        usedFallback = true
        isLoading = false
    }
}

#Preview {
    PreMatchBriefView()
        .modelContainer(for: Match.self, inMemory: true)
}
