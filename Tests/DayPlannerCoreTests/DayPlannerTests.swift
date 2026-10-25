import Foundation
import Testing
@testable import DayPlannerCore

@Suite("DayPlanner")
struct DayPlannerTests {
    @Test("empty day plan for today has no tasks or events")
    func emptyDayPlanForToday() {
        let clock = FixedClock(now: date(2026, 10, 25, 9, 0))
        let planner = DayPlanner(
            store: InMemoryPlannerStore(),
            clock: clock,
            calendar: EmptyCalendarReading(),
            reminders: EmptyRemindersReading(),
            notifier: NoOpTaskNotifying()
        )

        let plan = planner.dayPlan(for: clock.today)

        #expect(plan.date == clock.today)
        #expect(plan.openTasks.isEmpty)
        #expect(plan.completedTasks.isEmpty)
        #expect(plan.events.isEmpty)
    }
}

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    var c = DateComponents()
    c.year = y
    c.month = m
    c.day = d
    c.hour = h
    c.minute = min
    return Calendar.current.date(from: c)!
}

struct FixedClock: Clock {
    var now: Date
    var today: Date { Calendar.current.startOfDay(for: now) }
}
