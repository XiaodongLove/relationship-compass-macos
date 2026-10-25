import Foundation

public final class DayPlanner: @unchecked Sendable {
    private let store: PlannerStore
    private let clock: any Clock
    private let calendar: any CalendarReading
    private let reminders: any RemindersReading
    private let notifier: TaskNotifying

    public init(
        store: PlannerStore,
        clock: any Clock = SystemClock(),
        calendar: any CalendarReading = EmptyCalendarReading(),
        reminders: any RemindersReading = EmptyRemindersReading(),
        notifier: TaskNotifying = NoOpTaskNotifying()
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

    @discardableResult
    public func createTask(title: String, on day: Date) -> Task {
        var tasks = store.loadTasks()
        let dayStart = Calendar.current.startOfDay(for: day)
        let nextOrder = (tasks.filter { Calendar.current.isDate($0.promisedDay, inSameDayAs: dayStart) }.map(\.sortOrder).max() ?? -1) + 1
        let task = Task(title: title, promisedDay: dayStart, sortOrder: nextOrder)
        tasks.append(task)
        store.saveTasks(tasks)
        return task
    }

    public func complete(taskID: TaskID) {
        mutateTask(taskID) { $0.isCompleted = true }
        notifier.cancel(taskID: taskID)
    }

    public func uncomplete(taskID: TaskID) {
        mutateTask(taskID) { task in
            task.isCompleted = false
            if let fire = task.reminderFireDate {
                notifier.schedule(taskID: task.id, title: task.title, at: fire)
            }
        }
    }

    func mutateTask(_ id: TaskID, _ body: (inout Task) -> Void) {
        var tasks = store.loadTasks()
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        body(&tasks[idx])
        store.saveTasks(tasks)
    }

    @discardableResult
    public func capture(title: String, sourceReminderID: String? = nil) -> InboxItem {
        var inbox = store.loadInbox()
        let item = InboxItem(title: title, sourceReminderID: sourceReminderID)
        inbox.append(item)
        store.saveInbox(inbox)
        return item
    }

    public func deleteInboxItem(id: InboxItemID) {
        store.saveInbox(store.loadInbox().filter { $0.id != id })
    }

    @discardableResult
    public func commitToDay(inboxItemID: InboxItemID, day: Date) -> Task? {
        var inbox = store.loadInbox()
        guard let idx = inbox.firstIndex(where: { $0.id == inboxItemID }) else { return nil }
        let item = inbox.remove(at: idx)
        store.saveInbox(inbox)
        var tasks = store.loadTasks()
        let dayStart = Calendar.current.startOfDay(for: day)
        let nextOrder = (tasks.filter { Calendar.current.isDate($0.promisedDay, inSameDayAs: dayStart) }.map(\.sortOrder).max() ?? -1) + 1
        let task = Task(
            title: item.title,
            promisedDay: dayStart,
            sortOrder: nextOrder,
            sourceReminderID: item.sourceReminderID
        )
        tasks.append(task)
        store.saveTasks(tasks)
        return task
    }

    public func returnToInbox(taskID: TaskID) {
        var tasks = store.loadTasks()
        guard let idx = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        let task = tasks.remove(at: idx)
        store.saveTasks(tasks)
        notifier.cancel(taskID: taskID)
        _ = capture(title: task.title, sourceReminderID: task.sourceReminderID)
    }

    public func changePromisedDay(taskID: TaskID, to day: Date) {
        let dayStart = Calendar.current.startOfDay(for: day)
        let nextOrder = (store.loadTasks()
            .filter { $0.id != taskID && Calendar.current.isDate($0.promisedDay, inSameDayAs: dayStart) }
            .map(\.sortOrder).max() ?? -1) + 1
        mutateTask(taskID) { task in
            task.promisedDay = dayStart
            task.sortOrder = nextOrder
        }
    }

    public func reorder(taskIDs: [TaskID], on day: Date) {
        let dayStart = Calendar.current.startOfDay(for: day)
        var tasks = store.loadTasks()
        for (index, id) in taskIDs.enumerated() {
            guard let idx = tasks.firstIndex(where: { $0.id == id }) else { continue }
            guard Calendar.current.isDate(tasks[idx].promisedDay, inSameDayAs: dayStart) else { continue }
            tasks[idx].sortOrder = index
        }
        store.saveTasks(tasks)
    }

    public func setSoftWindow(taskID: TaskID, window: SoftWindow?) {
        mutateTask(taskID) { $0.softWindow = window }
    }

    public func setReminder(taskID: TaskID, at fireDate: Date?) {
        mutateTask(taskID) { task in
            task.reminderFireDate = fireDate
            if let fireDate {
                notifier.schedule(taskID: task.id, title: task.title, at: fireDate)
            } else {
                notifier.cancel(taskID: task.id)
            }
        }
    }

    @discardableResult
    public func importReminders() -> [InboxItem] {
        let existingIDs = Set(
            store.loadInbox().compactMap(\.sourceReminderID)
                + store.loadTasks().compactMap(\.sourceReminderID)
        )
        var created: [InboxItem] = []
        for reminder in reminders.unfinishedReminders() {
            guard !existingIDs.contains(reminder.id) else { continue }
            created.append(capture(title: reminder.title, sourceReminderID: reminder.id))
        }
        return created
    }

    public func planningRitualSnapshot() -> PlanningRitualSnapshot {
        PlanningRitualSnapshot(inbox: inboxItems(), overdue: overdueTasks())
    }
}

public struct PlanningRitualSnapshot: Equatable, Sendable {
    public var inbox: [InboxItem]
    public var overdue: [Task]
    public init(inbox: [InboxItem], overdue: [Task]) {
        self.inbox = inbox
        self.overdue = overdue
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
