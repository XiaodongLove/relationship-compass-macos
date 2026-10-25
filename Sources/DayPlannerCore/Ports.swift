import Foundation

public protocol Clock: Sendable {
    var now: Date { get }
    var today: Date { get }
}

public struct SystemClock: Clock {
    public init() {}
    public var now: Date { Date() }
    public var today: Date { Calendar.current.startOfDay(for: now) }
}

public protocol CalendarReading: Sendable {
    func events(on day: Date) -> [Event]
}

public struct EmptyCalendarReading: CalendarReading {
    public init() {}
    public func events(on day: Date) -> [Event] { [] }
}

public protocol RemindersReading: Sendable {
    func unfinishedReminders() -> [SystemReminder]
}

public struct EmptyRemindersReading: RemindersReading {
    public init() {}
    public func unfinishedReminders() -> [SystemReminder] { [] }
}

public protocol TaskNotifying: Sendable {
    func schedule(taskID: TaskID, title: String, at fireDate: Date)
    func cancel(taskID: TaskID)
}

public struct NoOpTaskNotifying: TaskNotifying {
    public init() {}
    public func schedule(taskID: TaskID, title: String, at fireDate: Date) {}
    public func cancel(taskID: TaskID) {}
}

public protocol PlannerStore: AnyObject {
    func loadInbox() -> [InboxItem]
    func saveInbox(_ items: [InboxItem])
    func loadTasks() -> [Task]
    func saveTasks(_ tasks: [Task])
}
