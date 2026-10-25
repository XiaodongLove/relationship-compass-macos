import EventKit
import Foundation

/// Read-only calendar adapter. Returns [] when access is denied.
public final class EventKitCalendarReading: CalendarReading, @unchecked Sendable {
    private let store = EKEventStore()

    public init() {}

    public func events(on day: Date) -> [Event] {
        let status = EKEventStore.authorizationStatus(for: .event)
        guard status == .fullAccess else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map {
            Event(id: $0.eventIdentifier ?? UUID().uuidString, title: $0.title ?? "(untitled)", start: $0.startDate, end: $0.endDate)
        }
    }

    public func requestAccessIfNeeded() async {
        _ = try? await store.requestFullAccessToEvents()
    }
}

/// Reminders import source. Returns [] when access is denied.
public final class EventKitRemindersReading: RemindersReading, @unchecked Sendable {
    private let store = EKEventStore()

    public init() {}

    public func unfinishedReminders() -> [SystemReminder] {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .fullAccess else { return [] }
        // nil due-date bounds include unfinished reminders with no due date
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        var result: [SystemReminder] = []
        let sem = DispatchSemaphore(value: 0)
        store.fetchReminders(matching: predicate) { reminders in
            result = (reminders ?? []).map {
                SystemReminder(id: $0.calendarItemIdentifier, title: $0.title ?? "(untitled)")
            }
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 2)
        return result
    }

    public func requestAccessIfNeeded() async {
        _ = try? await store.requestFullAccessToReminders()
    }
}
