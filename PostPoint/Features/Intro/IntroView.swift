import SwiftUI

struct IntroView: View {
    var onGetStarted: () -> Void

    @State private var currentPage = 0
    @State private var appeared = false

    private let pages = IntroPage.allPages

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        IntroPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                // Page indicator + CTA
                VStack(spacing: AppSpacing.lg) {
                    // Dots
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? AppColors.primary : AppColors.tertiaryLabel)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    if currentPage == pages.count - 1 {
                        // Final page CTA
                        PrimaryButton("Get Started", icon: "arrow.right") {
                            markIntroSeen()
                            onGetStarted()
                        }

                        Text("Takes less than a minute")
                            .font(AppFont.caption())
                            .foregroundStyle(AppColors.tertiaryLabel)
                    } else {
                        // Tap to continue
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continue")
                                .font(AppFont.headline())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            withAnimation { currentPage = pages.count - 1 }
                        } label: {
                            Text("Skip")
                                .font(AppFont.caption())
                                .foregroundStyle(AppColors.tertiaryLabel)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Persistence

    private static let hasSeenIntroKey = "PostPoint.hasSeenIntro"

    static var hasSeenIntro: Bool {
        UserDefaults.standard.bool(forKey: hasSeenIntroKey)
    }

    private func markIntroSeen() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenIntroKey)
    }
}

// MARK: - Page Model

private struct IntroPage {
    let icon: String
    let headline: String
    let subtext: String
    let callout: String?

    static let allPages: [IntroPage] = [
        IntroPage(
            icon: "chart.line.uptrend.xyaxis",
            headline: "Get better after\nevery match",
            subtext: "PostPoint turns your matches into clear, actionable coaching.",
            callout: nil
        ),
        IntroPage(
            icon: "bolt.fill",
            headline: "Debrief in under\na minute",
            subtext: "Log your match and get 3\u{2013}4 things to fix immediately.",
            callout: "Based on how you actually played"
        ),
        IntroPage(
            icon: "target",
            headline: "Show up\nwith a plan",
            subtext: "Before your next match, get 3 focus points tailored to you.",
            callout: "Not generic advice \u{2014} your patterns"
        ),
        IntroPage(
            icon: "arrow.trianglehead.2.clockwise",
            headline: "Use it after\nevery match",
            subtext: "That\u{2019}s where the improvement happens.",
            callout: nil
        ),
    ]
}

// MARK: - Page View

private struct IntroPageView: View {
    let page: IntroPage

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: page.icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .padding(.bottom, AppSpacing.sm)

            Text(page.headline)
                .font(.system(size: 32, weight: .bold, design: .default))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.label)

            Text(page.subtext)
                .font(AppFont.body())
                .foregroundStyle(AppColors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            if let callout = page.callout {
                Text(callout)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColors.primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

#Preview {
    IntroView { }
}
