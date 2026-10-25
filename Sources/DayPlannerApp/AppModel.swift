import Foundation
import DayPlannerCore

final class AppModel {
    let planner: DayPlanner
    private(set) var selectedDay: Date
    private(set) var plan: DayPlan
    var onChange: (() -> Void)?

    init(planner: DayPlanner? = nil) {
        let p = planner ?? DayPlanner(store: FilePlannerStore())
        self.planner = p
        let today = Calendar.current.startOfDay(for: Date())
        self.selectedDay = today
        self.plan = p.dayPlan(for: today)
    }

    func refresh() {
        plan = planner.dayPlan(for: selectedDay)
        onChange?()
    }

    func selectDay(_ day: Date) {
        selectedDay = Calendar.current.startOfDay(for: day)
        refresh()
    }
}
