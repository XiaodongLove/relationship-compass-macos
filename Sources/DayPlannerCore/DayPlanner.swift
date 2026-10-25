import Foundation

public final class DayPlanner: @unchecked Sendable {
    private let store: PlannerStore
    private let clock: any Clock
    private let calendar: any CalendarReading
    private let reminders: any RemindersReading
    private let notifier: any TaskNotifying

    public init(
        store: PlannerStore,
        clock: any Clock = SystemClock(),
        calendar: any CalendarReading = EmptyCalendarReading(),
        reminders: any RemindersReading = EmptyRemindersReading(),
        notifier: any TaskNotifying = NoOpTaskNotifying()
    ) {
        self.store = store
        self.clock = clock
        self.calendar = calendar
        self.reminders = reminders
        self.notifier = notifier
    }

    public func dayPlan(for day: Date) -> DayPlan {
        let dayStart = Calendar.current.startOfDay(for: day)
        let tasks = store.loadTasks().filter { Calendar.current.isDate($0.promisedDay, inSameDayAs: dayStart) }
        let open = tasks.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = tasks.filter(\.isCompleted).sorted { $0.sortOrder < $1.sortOrder }
        let events = calendar.events(on: dayStart)
        return DayPlan(
            date: dayStart,
            openTasks: open,
            completedTasks: completed,
            events: events,
            softWindowOverlapHints: SoftWindowOverlap.hints(tasks: open, events: events, calendar: Calendar.current)
        )
    }

    public func inboxItems() -> [InboxItem] {
        store.loadInbox()
    }

    public func overdueTasks() -> [Task] {
        let today = clock.today
        return store.loadTasks()
            .filter { !$0.isCompleted && $0.promisedDay < today }
            .sorted { $0.promisedDay < $1.promisedDay }
    }
}

enum SoftWindowOverlap {
    static func hints(tasks: [Task], events: [Event], calendar: Calendar) -> Set<TaskID> {
        guard !events.isEmpty else { return [] }
        var result: Set<TaskID> = []
        for task in tasks {
            guard let window = task.softWindow else { continue }
            guard let range = range(for: window, on: task.promisedDay, calendar: calendar) else { continue }
            if events.contains(where: { $0.start < range.upperBound && $0.end > range.lowerBound }) {
                result.insert(task.id)
            }
        }
        return result
    }

    static func range(for window: SoftWindow, on day: Date, calendar: Calendar) -> Range<Date>? {
        let start = calendar.startOfDay(for: day)
        switch window {
        case .morning:
            guard let a = calendar.date(byAdding: .hour, value: 6, to: start),
                  let b = calendar.date(byAdding: .hour, value: 12, to: start) else { return nil }
            return a..<b
        case .afternoon:
            guard let a = calendar.date(byAdding: .hour, value: 12, to: start),
                  let b = calendar.date(byAdding: .hour, value: 18, to: start) else { return nil }
            return a..<b
        case .evening:
            guard let a = calendar.date(byAdding: .hour, value: 18, to: start),
                  let b = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            return a..<b
        case .clock(let components):
            var c = calendar.dateComponents([.year, .month, .day], from: start)
            c.hour = components.hour ?? 0
            c.minute = components.minute ?? 0
            guard let point = calendar.date(from: c),
                  let end = calendar.date(byAdding: .hour, value: 1, to: point) else { return nil }
            return point..<end
        }
    }
}
