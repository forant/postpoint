import Foundation
import AuthenticationServices
import Security

/// Manages Sign in with Apple identity and links it to the local anonymous user.
///
/// Auth states:
/// - `.anonymous`: Default. User has a local UUID but no Apple account linked.
/// - `.signedInWithApple`: User completed SIWA. Apple user ID stored in Keychain.
@Observable
final class AuthService {
    static let shared = AuthService()

    // MARK: - State

    enum AuthState: String, Codable {
        case anonymous
        case signedInWithApple
    }

    private(set) var authState: AuthState
    private(set) var appleUserId: String?
    private(set) var userEmail: String?
    private(set) var userFullName: String?

    // MARK: - Suppression

    /// Timestamp of the last SIWA dismissal. Nil if never dismissed.
    private static var lastSIWADismissDate: Date? {
        get { UserDefaults.standard.object(forKey: "PostPoint.lastSIWADismissDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "PostPoint.lastSIWADismissDate") }
    }

    /// Number of debriefs completed at the time of last SIWA dismissal.
    private static var debriefCountAtLastDismiss: Int {
        get { UserDefaults.standard.integer(forKey: "PostPoint.debriefCountAtLastSIWADismiss") }
        set { UserDefaults.standard.set(newValue, forKey: "PostPoint.debriefCountAtLastSIWADismiss") }
    }

    /// Whether the user should see the SIWA prompt.
    /// Re-prompts after 7 days or 4 additional debriefs since last dismissal.
    func shouldPromptSIWA(debriefCount: Int) -> Bool {
        guard authState == .anonymous else { return false }

        // Never dismissed before — show on first debrief
        guard let lastDismiss = Self.lastSIWADismissDate else { return true }

        let daysSinceDismiss = Calendar.current.dateComponents([.day], from: lastDismiss, to: Date()).day ?? 0
        if daysSinceDismiss >= 7 { return true }

        let debriefsSinceDismiss = debriefCount - Self.debriefCountAtLastDismiss
        if debriefsSinceDismiss >= 4 { return true }

        return false
    }

    // MARK: - Init

    private init() {
        // Restore state from Keychain + UserDefaults
        if let storedAppleId = KeychainHelper.read(key: Keys.appleUserId) {
            appleUserId = storedAppleId
            authState = .signedInWithApple
            userEmail = UserDefaults.standard.string(forKey: Keys.email)
            userFullName = UserDefaults.standard.string(forKey: Keys.fullName)
        } else {
            authState = .anonymous
        }
    }

    // MARK: - SIWA Completion

    /// Called when Sign in with Apple succeeds.
    func handleSignIn(credential: ASAuthorizationAppleIDCredential) {
        let appleId = credential.user

        // Store Apple user ID in Keychain
        KeychainHelper.save(key: Keys.appleUserId, value: appleId)
        appleUserId = appleId

        // Email and full name are only provided on first sign-in
        if let email = credential.email {
            userEmail = email
            UserDefaults.standard.set(email, forKey: Keys.email)
        }

        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                userFullName = name
                UserDefaults.standard.set(name, forKey: Keys.fullName)
            }
        }

        // Link Apple ID to existing anonymous UUID
        UserIdentityService.shared.linkAppleId(appleId)

        authState = .signedInWithApple

        AnalyticsService.track(.siwaCompleted, properties: [
            "has_email": credential.email != nil,
            "has_name": credential.fullName?.givenName != nil,
        ])
    }

    /// Called when user dismisses the SIWA prompt without signing in.
    /// Records the current time and debrief count so re-prompt logic can check cooldowns.
    func dismissSIWAPrompt(debriefCount: Int) {
        Self.lastSIWADismissDate = Date()
        Self.debriefCountAtLastDismiss = debriefCount
        AnalyticsService.track(.siwaDismissed)
    }

    /// Check if the Apple credential is still valid (call on app launch or periodically).
    func checkCredentialState() {
        guard let appleId = appleUserId else { return }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleId) { state, _ in
            DispatchQueue.main.async {
                switch state {
                case .revoked, .notFound:
                    self.signOut()
                case .authorized:
                    break
                case .transferred:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    /// Signs out locally (clears Apple identity, reverts to anonymous).
    func signOut() {
        KeychainHelper.delete(key: Keys.appleUserId)
        UserDefaults.standard.removeObject(forKey: Keys.email)
        UserDefaults.standard.removeObject(forKey: Keys.fullName)
        appleUserId = nil
        userEmail = nil
        userFullName = nil
        authState = .anonymous
    }

    // MARK: - Display Helpers

    var displayName: String {
        if let name = userFullName, !name.isEmpty { return name }
        if let profile = PlayerProfile.load() { return profile.firstName }
        return "Player"
    }

    var isSignedIn: Bool { authState == .signedInWithApple }

    // MARK: - Keys

    private enum Keys {
        static let appleUserId = "PostPoint.appleUserId"
        static let email = "PostPoint.appleEmail"
        static let fullName = "PostPoint.appleFullName"
    }
}

// MARK: - Keychain Helper

private enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
