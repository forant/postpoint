import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var authError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: authService.isSignedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                            .font(.title)
                            .foregroundStyle(AppColors.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.displayName)
                                .font(AppFont.headline())
                            if authService.isSignedIn {
                                Text(authService.userEmail ?? "Apple Account linked")
                                    .font(AppFont.caption())
                                    .foregroundStyle(AppColors.secondaryLabel)
                            } else {
                                Text("Anonymous account")
                                    .font(AppFont.caption())
                                    .foregroundStyle(AppColors.secondaryLabel)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }

                if !authService.isSignedIn {
                    Section {
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            handleResult(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 44)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } footer: {
                        Text("Link your account to keep your match history safe.")
                    }

                    if let authError {
                        Section {
                            Text(authError)
                                .font(AppFont.caption())
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    Section {
                        Button(role: .destructive) {
                            authService.signOut()
                        } label: {
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Unexpected credential type."
                return
            }
            authService.handleSignIn(credential: credential)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            if nsError.code == ASAuthorizationError.unknown.rawValue {
                authError = "Make sure you're signed into an Apple Account in Settings, then try again."
            } else {
                authError = "Could not complete sign in. Try again later."
            }
        }
    }
}
