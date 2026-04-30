import SwiftUI

struct SplashScreenView: View {
    var onFinished: () -> Void

    @State private var iconOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.96
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 10
    @State private var fadeOut: Double = 1

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .opacity(iconOpacity)
                    .scaleEffect(iconScale)

                Text("PostPoint")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.14, blue: 0.2))
                    .opacity(wordmarkOpacity)
                    .offset(y: wordmarkOffset)
            }
            .offset(y: -20) // slightly above center
        }
        .opacity(fadeOut)
        .onAppear {
            runAnimation()
        }
    }

    private func runAnimation() {
        // Icon fades in and scales up
        withAnimation(.easeOut(duration: 0.5)) {
            iconOpacity = 1
            iconScale = 1.0
        }

        // Wordmark fades in slightly after
        withAnimation(.easeOut(duration: 0.45).delay(0.25)) {
            wordmarkOpacity = 1
            wordmarkOffset = 0
        }

        // Subtle pulse on icon
        withAnimation(.easeInOut(duration: 0.3).delay(0.6)) {
            iconScale = 1.03
        }
        withAnimation(.easeInOut(duration: 0.25).delay(0.9)) {
            iconScale = 1.0
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.4).delay(1.2)) {
            fadeOut = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            onFinished()
        }
    }
}

#Preview {
    SplashScreenView { }
}
