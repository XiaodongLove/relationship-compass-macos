import Foundation

public final class InMemoryPlannerStore: PlannerStore, @unchecked Sendable {
    private var inbox: [InboxItem] = []
    private var tasks: [Task] = []

    public init() {}

    public func loadInbox() -> [InboxItem] { inbox }
    public func saveInbox(_ items: [InboxItem]) { inbox = items }
    public func loadTasks() -> [Task] { tasks }
    public func saveTasks(_ tasks: [Task]) { self.tasks = tasks }
}
