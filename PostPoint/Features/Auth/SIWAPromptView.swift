import SwiftUI
import AuthenticationServices

struct SIWAPromptView: View {
    let onComplete: () -> Void

    @State private var authError: String?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)

            VStack(spacing: AppSpacing.sm) {
                Text("Save your match history")
                    .font(AppFont.largeTitle())
                    .multilineTextAlignment(.center)

                Text("Sign in to keep your data safe across devices. Your matches and debriefs stay with you.")
                    .font(AppFont.body())
                    .foregroundStyle(AppColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    handleResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    onComplete()
                } label: {
                    Text("Not now")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColors.secondaryLabel)
                }

                if let authError {
                    Text(authError)
                        .font(AppFont.caption())
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Unexpected credential type."
                return
            }
            AuthService.shared.handleSignIn(credential: credential)
            onComplete()
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            // Unknown error (1000) typically means no Apple ID is signed in on the device
            if nsError.code == ASAuthorizationError.unknown.rawValue {
                authError = "Make sure you're signed into an Apple Account in Settings, then try again."
            } else if nsError.code == ASAuthorizationError.notHandled.rawValue || nsError.code == ASAuthorizationError.notInteractive.rawValue {
                authError = "Could not complete sign in. Try again later."
            } else {
                authError = "Sign in failed. Try again."
            }
        }
    }
}
