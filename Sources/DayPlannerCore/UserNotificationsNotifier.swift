import Foundation
import UserNotifications

public final class UserNotificationsNotifier: TaskNotifying, @unchecked Sendable {
    public init() {}

    public func schedule(taskID: TaskID, title: String, at fireDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = title
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: taskID.raw.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    public func cancel(taskID: TaskID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskID.raw.uuidString])
    }
}
