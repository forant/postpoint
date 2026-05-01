import Foundation

/// Provides a stable anonymous user identity for analytics and future account migration.
///
/// - `anonymousUserId` is the local pre-account identity, generated once and persisted.
/// - Future Sign in with Apple can link `anonymousUserId` to a real `accountId`.
/// - Do NOT replace this with device identifiers (IDFA, IDFV, hardware IDs).
final class UserIdentityService {
    static let shared = UserIdentityService()

    private static let userIdKey = "PostPoint.anonymousUserId"

    /// Stable anonymous UUID string, created once and reused across launches.
    let anonymousUserId: String

    private static let linkedAppleIdKey = "PostPoint.linkedAppleId"

    /// The Apple user ID linked to this anonymous identity, if any.
    private(set) var linkedAppleId: String?

    private init() {
        if let existing = UserDefaults.standard.string(forKey: Self.userIdKey) {
            anonymousUserId = existing
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: Self.userIdKey)
            anonymousUserId = newId
        }
        linkedAppleId = UserDefaults.standard.string(forKey: Self.linkedAppleIdKey)
    }

    /// Links the anonymous user to an Apple ID from Sign in with Apple.
    func linkAppleId(_ appleId: String) {
        linkedAppleId = appleId
        UserDefaults.standard.set(appleId, forKey: Self.linkedAppleIdKey)
    }
}
