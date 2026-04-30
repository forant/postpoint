import Foundation
import UserNotifications

/// Manages next match scheduling, notification permission, and local notification lifecycle.
enum NextMatchService {
    private static let matchDayNotificationId = "PostPoint.nextMatchReminder"
    private static let dayBeforeNotificationId = "PostPoint.nextMatchDayBefore"

    // MARK: - Save / Update

    /// Saves the next match and schedules a notification. Requests permission if needed.
    static func save(_ nextMatch: NextMatch) {
        var match = nextMatch
        match.updatedAt = Date()
        match.save()

        scheduleNotification(for: match)

        AnalyticsService.track(.nextMatchSet, properties: [
            "sport": match.sport.rawValue,
            "has_opponent": match.opponentName != nil,
            "days_until_match": Calendar.current.dateComponents([.day], from: Date(), to: match.scheduledDate).day ?? 0,
        ])
    }

    /// Clears the saved next match and cancels any pending notifications.
    static func clear() {
        NextMatch.clear()
        cancelNotifications()
    }

    // MARK: - Notifications

    private static func scheduleNotification(for match: NextMatch) {
        let center = UNUserNotificationCenter.current()

        // Request permission only when user sets a next match
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else {
                #if DEBUG
                print("[NextMatch] Notification permission denied: \(error?.localizedDescription ?? "unknown")")
                #endif
                return
            }

            // Cancel any existing notifications first
            center.removePendingNotificationRequests(withIdentifiers: [
                matchDayNotificationId,
                dayBeforeNotificationId,
            ])

            // 1. Day-before notification (6 PM evening before)
            scheduleDayBeforeNotification(for: match, center: center)

            // 2. Match-day notification (8 AM)
            scheduleMatchDayNotification(for: match, center: center)

            // Update notification timestamp
            var updated = match
            updated.notificationScheduledAt = Date()
            updated.save()
        }
    }

    private static func scheduleMatchDayNotification(for match: NextMatch, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "Today's match focus"
        content.body = "Tap for 3 quick things to keep in mind before you play."
        content.sound = .default
        content.userInfo = ["type": "pre_match_brief", "nextMatchId": match.id.uuidString]

        let trigger = buildTrigger(for: match.scheduledDate, hour: 8, minute: 0)

        let request = UNNotificationRequest(
            identifier: matchDayNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error { print("[NextMatch] Failed to schedule match-day notification: \(error)") }
            else { print("[NextMatch] Match-day notification scheduled for \(match.scheduledDate)") }
            #endif
        }
    }

    private static func scheduleDayBeforeNotification(for match: NextMatch, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: match.scheduledDate) else { return }

        // Only schedule if the day before is still in the future
        var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = 18
        components.minute = 0
        guard let triggerDate = calendar.date(from: components), triggerDate > Date() else { return }

        let opponentPart = match.opponentName.map { " against \($0)" } ?? ""
        let content = UNMutableNotificationContent()
        content.title = "Match tomorrow\(opponentPart)"
        content.body = "Your pre-match focus is ready. Tap to review."
        content.sound = .default
        content.userInfo = ["type": "pre_match_brief", "nextMatchId": match.id.uuidString]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: dayBeforeNotificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error { print("[NextMatch] Failed to schedule day-before notification: \(error)") }
            else { print("[NextMatch] Day-before notification scheduled for \(dayBefore)") }
            #endif
        }
    }

    private static func buildTrigger(for matchDate: Date, hour: Int, minute: Int) -> UNNotificationTrigger {
        let calendar = Calendar.current

        var targetComponents = calendar.dateComponents([.year, .month, .day], from: matchDate)
        targetComponents.hour = hour
        targetComponents.minute = minute

        guard let targetDate = calendar.date(from: targetComponents) else {
            return UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        }

        if targetDate <= Date() {
            return UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        }

        return UNCalendarNotificationTrigger(dateMatching: targetComponents, repeats: false)
    }

    private static func cancelNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [
                matchDayNotificationId,
                dayBeforeNotificationId,
            ])
    }
}
