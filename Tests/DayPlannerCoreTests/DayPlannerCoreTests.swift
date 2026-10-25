import DayPlannerSuite
import Testing

@Suite("DayPlanner")
struct DayPlannerCoreTests {
    @Test("DayPlanner facade suite")
    func facadeSuite() {
        #expect(DayPlannerSuite.runAll() == 0)
    }
}
