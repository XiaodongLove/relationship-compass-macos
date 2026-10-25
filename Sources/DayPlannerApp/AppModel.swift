import Foundation
import DayPlannerCore

final class AppModel {
    let planner: DayPlanner
    private(set) var selectedDay: Date
    private(set) var plan: DayPlan
    private(set) var inbox: [InboxItem] = []
    private(set) var overdue: [DayPlannerCore.Task] = []
    var onChange: (() -> Void)?
    private let calendarReader: EventKitCalendarReading
    private let remindersReader: EventKitRemindersReading

    init(planner: DayPlanner? = nil) {
        let calendar = EventKitCalendarReading()
        let reminders = EventKitRemindersReading()
        self.calendarReader = calendar
        self.remindersReader = reminders
        let p = planner ?? DayPlanner(
            store: FilePlannerStore(),
            calendar: calendar,
            reminders: reminders,
            notifier: UserNotificationsNotifier()
        )
        self.planner = p
        let today = Calendar.current.startOfDay(for: Date())
        self.selectedDay = today
        self.plan = p.dayPlan(for: today)
        refresh()
    }

    func requestSystemAccess() {
        let calendar = calendarReader
        let reminders = remindersReader
        Swift.Task {
            await calendar.requestAccessIfNeeded()
            await reminders.requestAccessIfNeeded()
        }
    }

    func refresh() {
        plan = planner.dayPlan(for: selectedDay)
        inbox = planner.inboxItems()
        overdue = planner.overdueTasks()
        onChange?()
    }

    func selectDay(_ day: Date) {
        selectedDay = Calendar.current.startOfDay(for: day)
        refresh()
    }

    func createTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = planner.createTask(title: title, on: selectedDay)
        refresh()
    }

    func toggleComplete(_ task: DayPlannerCore.Task) {
        if task.isCompleted { planner.uncomplete(taskID: task.id) }
        else { planner.complete(taskID: task.id) }
        refresh()
    }

    func capture(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = planner.capture(title: title)
        refresh()
    }

    func commitInbox(_ item: InboxItem) {
        _ = planner.commitToDay(inboxItemID: item.id, day: selectedDay)
        refresh()
    }

    func returnToInbox(_ task: DayPlannerCore.Task) {
        planner.returnToInbox(taskID: task.id)
        refresh()
    }

    func setSoftWindow(_ task: DayPlannerCore.Task, _ window: SoftWindow?) {
        planner.setSoftWindow(taskID: task.id, window: window)
        refresh()
    }

    func reorderOpen(by idOrder: [TaskID]) {
        planner.reorder(taskIDs: idOrder, on: selectedDay)
        refresh()
    }

    func setReminder(_ task: DayPlannerCore.Task, at date: Date?) {
        planner.setReminder(taskID: task.id, at: date)
        refresh()
    }

    func importReminders() {
        _ = planner.importReminders()
        refresh()
    }

    func moveOverdueToToday(_ task: DayPlannerCore.Task) {
        planner.changePromisedDay(taskID: task.id, to: Calendar.current.startOfDay(for: Date()))
        refresh()
    }

    @discardableResult
    func importFuzzyDescription(_ text: String) -> [DayPlannerCore.Task] {
        let created = planner.importFuzzyDescription(text, on: selectedDay)
        refresh()
        return created
    }

    func setPriority(_ task: DayPlannerCore.Task, _ priority: Priority) {
        planner.setPriority(taskID: task.id, priority: priority)
        refresh()
    }
}
