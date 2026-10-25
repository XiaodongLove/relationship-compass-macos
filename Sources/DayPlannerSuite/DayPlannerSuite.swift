import Foundation
import DayPlannerCore

/// Runnable DayPlanner facade suite (works without XCTest / Testing macros).
public enum DayPlannerSuite {
    public static func runAll() -> Int {
        let counter = Counter()
        emptyDayPlan(counter)
        createCompleteUncomplete(counter)
        inboxCaptureAndCommit(counter)
        softWindowAndReorder(counter)
        moveOverduePastDays(counter)
        eventsAndOverlapHint(counter)
        taskReminders(counter)
        remindersImportDedupe(counter)
        ritualSurfaces(counter)
        if counter.failures == 0 {
            print("All tests passed.")
        } else {
            print("\(counter.failures) failure(s).")
        }
        return counter.failures
    }
}

private final class Counter {
    var failures = 0
    func expect(_ condition: @autoclosure () -> Bool, _ message: String, file: StaticString = #fileID, line: UInt = #line) {
        if !condition() {
            failures += 1
            print("FAIL \(file):\(line): \(message)")
        }
    }
}

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
    return Calendar.current.date(from: c)!
}

private struct FixedClock: Clock {
    var now: Date
    var today: Date { Calendar.current.startOfDay(for: now) }
}

private final class RecordingNotifier: TaskNotifying {
    private(set) var scheduled: [(TaskID, String, Date)] = []
    private(set) var cancelled: [TaskID] = []
    func schedule(taskID: TaskID, title: String, at fireDate: Date) {
        scheduled.append((taskID, title, fireDate))
    }
    func cancel(taskID: TaskID) { cancelled.append(taskID) }
}

private struct FakeCalendar: CalendarReading {
    var eventsByDay: [Date: [Event]] = [:]
    func events(on day: Date) -> [Event] {
        eventsByDay[Calendar.current.startOfDay(for: day)] ?? []
    }
}

private struct FakeReminders: RemindersReading {
    var items: [SystemReminder] = []
    func unfinishedReminders() -> [SystemReminder] { items }
}

private func makePlanner(
    clock: FixedClock,
    store: InMemoryPlannerStore = InMemoryPlannerStore(),
    calendar: any CalendarReading = EmptyCalendarReading(),
    reminders: any RemindersReading = EmptyRemindersReading(),
    notifier: TaskNotifying = NoOpTaskNotifying()
) -> DayPlanner {
    DayPlanner(store: store, clock: clock, calendar: calendar, reminders: reminders, notifier: notifier)
}

private func section(_ name: String, _ body: () -> Void) {
    print("— \(name)")
    body()
}

private func emptyDayPlan(_ c: Counter) {
    section("empty day plan") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let plan = makePlanner(clock: clock).dayPlan(for: clock.today)
        c.expect(plan.date == clock.today, "date is today")
        c.expect(plan.openTasks.isEmpty, "no open tasks")
        c.expect(plan.completedTasks.isEmpty, "no completed")
        c.expect(plan.events.isEmpty, "no events")
    }
}

private func createCompleteUncomplete(_ c: Counter) {
    section("create complete uncomplete") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let planner = makePlanner(clock: clock)
        let task = planner.createTask(title: "Write report", on: clock.today)
        c.expect(planner.dayPlan(for: clock.today).openTasks.map(\.id) == [task.id], "created open")
        planner.complete(taskID: task.id)
        c.expect(planner.dayPlan(for: clock.today).completedTasks.map(\.id) == [task.id], "completed section")
        c.expect(planner.dayPlan(for: clock.today).openTasks.isEmpty, "open empty after complete")
        planner.uncomplete(taskID: task.id)
        c.expect(planner.dayPlan(for: clock.today).openTasks.map(\.id) == [task.id], "uncompleted")
    }
}

private func inboxCaptureAndCommit(_ c: Counter) {
    section("inbox capture and commit") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let planner = makePlanner(clock: clock)
        let item = planner.capture(title: "Buy milk")
        c.expect(planner.inboxItems().map(\.id) == [item.id], "in inbox")
        let task = planner.commitToDay(inboxItemID: item.id, day: clock.today)!
        c.expect(planner.inboxItems().isEmpty, "inbox empty after commit")
        c.expect(planner.dayPlan(for: clock.today).openTasks.map(\.id) == [task.id], "on day plan")
    }
}

private func softWindowAndReorder(_ c: Counter) {
    section("soft window and reorder") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let planner = makePlanner(clock: clock)
        let a = planner.createTask(title: "A", on: clock.today)
        let b = planner.createTask(title: "B", on: clock.today)
        planner.reorder(taskIDs: [b.id, a.id], on: clock.today)
        c.expect(planner.dayPlan(for: clock.today).openTasks.map(\.id) == [b.id, a.id], "reordered")
        planner.setSoftWindow(taskID: a.id, window: .morning)
        c.expect(planner.dayPlan(for: clock.today).openTasks.first(where: { $0.id == a.id })?.softWindow == .morning, "soft window set")
    }
}

private func moveOverduePastDays(_ c: Counter) {
    section("move overdue past days") {
        let store = InMemoryPlannerStore()
        var clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let planner = makePlanner(clock: clock, store: store)
        let task = planner.createTask(title: "Old", on: clock.today)
        clock = FixedClock(now: date(2026, 10, 26, 9, 0))
        let planner2 = makePlanner(clock: clock, store: store)
        c.expect(planner2.overdueTasks().map(\.id) == [task.id], "overdue next day")
        c.expect(planner2.dayPlan(for: date(2026, 10, 25)).openTasks.map(\.id) == [task.id], "still on original day")
        planner2.returnToInbox(taskID: task.id)
        c.expect(planner2.inboxItems().map(\.title) == ["Old"], "returned to inbox")
        c.expect(planner2.dayPlan(for: date(2026, 10, 25)).openTasks.isEmpty, "removed from day")
        let t2 = planner2.createTask(title: "Move me", on: clock.today)
        planner2.changePromisedDay(taskID: t2.id, to: date(2026, 10, 27))
        c.expect(planner2.dayPlan(for: date(2026, 10, 27)).openTasks.map(\.id) == [t2.id], "changed day")
    }
}

private func eventsAndOverlapHint(_ c: Counter) {
    section("events and soft window overlap hint") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let cal = FakeCalendar(eventsByDay: [
            clock.today: [Event(id: "e1", title: "Standup", start: date(2026, 10, 25, 10, 0), end: date(2026, 10, 25, 10, 30))]
        ])
        let planner = makePlanner(clock: clock, calendar: cal)
        let task = planner.createTask(title: "Deep work", on: clock.today)
        planner.setSoftWindow(taskID: task.id, window: .morning)
        let plan = planner.dayPlan(for: clock.today)
        c.expect(plan.events.count == 1, "events present")
        c.expect(plan.softWindowOverlapHints.contains(task.id), "overlap hint")
    }
}

private func taskReminders(_ c: Counter) {
    section("task reminders") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let notifier = RecordingNotifier()
        let planner = makePlanner(clock: clock, notifier: notifier)
        let task = planner.createTask(title: "Call", on: clock.today)
        let fire = date(2026, 10, 25, 15, 0)
        planner.setReminder(taskID: task.id, at: fire)
        c.expect(notifier.scheduled.contains(where: { $0.0 == task.id && $0.2 == fire }), "scheduled")
        planner.complete(taskID: task.id)
        c.expect(notifier.cancelled.contains(task.id), "cancelled on complete")
    }
}

private func remindersImportDedupe(_ c: Counter) {
    section("reminders import dedupe") {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let reminders = FakeReminders(items: [SystemReminder(id: "r1", title: "Cat food")])
        let planner = makePlanner(clock: clock, reminders: reminders)
        let first = planner.importReminders()
        c.expect(first.count == 1, "imported one")
        c.expect(planner.inboxItems().map(\.sourceReminderID) == ["r1"], "source id stored")
        let second = planner.importReminders()
        c.expect(second.isEmpty, "deduped")
        c.expect(planner.inboxItems().count == 1, "still one")
        let id = planner.inboxItems()[0].id
        planner.deleteInboxItem(id: id)
        let third = planner.importReminders()
        c.expect(third.count == 1, "re-import after delete")
    }
}

private func ritualSurfaces(_ c: Counter) {
    section("ritual surfaces") {
        let store = InMemoryPlannerStore()
        let clock = FixedClock(now: date(2026, 10, 26, 9, 0))
        let planner = makePlanner(clock: FixedClock(now: date(2026, 10, 25, 9, 0)), store: store)
        _ = planner.createTask(title: "Prior day task", on: date(2026, 10, 25))
        _ = planner.capture(title: "New idea")
        let planner2 = makePlanner(clock: clock, store: store)
        let ritual = planner2.planningRitualSnapshot()
        c.expect(ritual.inbox.count == 1, "ritual inbox")
        c.expect(ritual.overdue.count == 1, "ritual overdue")
    }
}
