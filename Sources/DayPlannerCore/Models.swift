import Foundation

public struct TaskID: Hashable, Sendable, Codable {
    public let raw: UUID
    public init(_ raw: UUID = UUID()) { self.raw = raw }
}

public struct InboxItemID: Hashable, Sendable, Codable {
    public let raw: UUID
    public init(_ raw: UUID = UUID()) { self.raw = raw }
}

public struct InboxItem: Equatable, Sendable, Identifiable {
    public let id: InboxItemID
    public var title: String
    public var sourceReminderID: String?

    public init(id: InboxItemID = InboxItemID(), title: String, sourceReminderID: String? = nil) {
        self.id = id
        self.title = title
        self.sourceReminderID = sourceReminderID
    }
}

public enum SoftWindow: Equatable, Sendable, Codable {
    case morning
    case afternoon
    case evening
    case clock(DateComponents)
}

public enum Priority: Int, Equatable, Sendable, Codable, Comparable {
    case high = 0
    case medium = 1
    case low = 2

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct Task: Equatable, Sendable, Identifiable {
    public let id: TaskID
    public var title: String
    public var promisedDay: Date
    public var isCompleted: Bool
    public var sortOrder: Int
    public var priority: Priority
    public var softWindow: SoftWindow?
    public var reminderFireDate: Date?
    public var sourceReminderID: String?

    public init(
        id: TaskID = TaskID(),
        title: String,
        promisedDay: Date,
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        priority: Priority = .medium,
        softWindow: SoftWindow? = nil,
        reminderFireDate: Date? = nil,
        sourceReminderID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.promisedDay = Calendar.current.startOfDay(for: promisedDay)
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.priority = priority
        self.softWindow = softWindow
        self.reminderFireDate = reminderFireDate
        self.sourceReminderID = sourceReminderID
    }
}

public struct FuzzyDraft: Equatable, Sendable {
    public var title: String
    public var priority: Priority

    public init(title: String, priority: Priority) {
        self.title = title
        self.priority = priority
    }
}

public struct Event: Equatable, Sendable, Identifiable {
    public let id: String
    public var title: String
    public var start: Date
    public var end: Date

    public init(id: String, title: String, start: Date, end: Date) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
    }
}

public struct SystemReminder: Equatable, Sendable {
    public let id: String
    public var title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct DayPlan: Equatable, Sendable {
    public var date: Date
    public var openTasks: [Task]
    public var completedTasks: [Task]
    public var events: [Event]
    /// Task IDs whose Soft Window weakly overlaps an Event.
    public var softWindowOverlapHints: Set<TaskID>

    public init(
        date: Date,
        openTasks: [Task] = [],
        completedTasks: [Task] = [],
        events: [Event] = [],
        softWindowOverlapHints: Set<TaskID> = []
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.openTasks = openTasks
        self.completedTasks = completedTasks
        self.events = events
        self.softWindowOverlapHints = softWindowOverlapHints
    }
}
