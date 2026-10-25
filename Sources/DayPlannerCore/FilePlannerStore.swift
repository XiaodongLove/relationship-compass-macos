import Foundation

/// JSON file-backed local store (no cloud).
public final class FilePlannerStore: PlannerStore, @unchecked Sendable {
    private let url: URL
    private let queue = DispatchQueue(label: "FilePlannerStore")

    private struct Snapshot: Codable {
        var inbox: [CodableInbox]
        var tasks: [CodableTask]
    }

    private struct CodableInbox: Codable {
        var id: UUID
        var title: String
        var sourceReminderID: String?
    }

    private struct CodableTask: Codable {
        var id: UUID
        var title: String
        var promisedDay: Date
        var isCompleted: Bool
        var sortOrder: Int
        var softWindow: SoftWindow?
        var reminderFireDate: Date?
        var sourceReminderID: String?
    }

    public init(directory: URL = FilePlannerStore.defaultDirectory()) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appendingPathComponent("planner.json")
    }

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("DayPlanner", isDirectory: true)
    }

    public func loadInbox() -> [InboxItem] {
        queue.sync { load().inbox.map { InboxItem(id: InboxItemID($0.id), title: $0.title, sourceReminderID: $0.sourceReminderID) } }
    }

    public func saveInbox(_ items: [InboxItem]) {
        queue.sync {
            var snap = load()
            snap.inbox = items.map { CodableInbox(id: $0.id.raw, title: $0.title, sourceReminderID: $0.sourceReminderID) }
            persist(snap)
        }
    }

    public func loadTasks() -> [Task] {
        queue.sync {
            load().tasks.map {
                Task(
                    id: TaskID($0.id),
                    title: $0.title,
                    promisedDay: $0.promisedDay,
                    isCompleted: $0.isCompleted,
                    sortOrder: $0.sortOrder,
                    softWindow: $0.softWindow,
                    reminderFireDate: $0.reminderFireDate,
                    sourceReminderID: $0.sourceReminderID
                )
            }
        }
    }

    public func saveTasks(_ tasks: [Task]) {
        queue.sync {
            var snap = load()
            snap.tasks = tasks.map {
                CodableTask(
                    id: $0.id.raw,
                    title: $0.title,
                    promisedDay: $0.promisedDay,
                    isCompleted: $0.isCompleted,
                    sortOrder: $0.sortOrder,
                    softWindow: $0.softWindow,
                    reminderFireDate: $0.reminderFireDate,
                    sourceReminderID: $0.sourceReminderID
                )
            }
            persist(snap)
        }
    }

    private func load() -> Snapshot {
        guard let data = try? Data(contentsOf: url),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return Snapshot(inbox: [], tasks: [])
        }
        return snap
    }

    private func persist(_ snap: Snapshot) {
        let data = try? JSONEncoder().encode(snap)
        try? data?.write(to: url, options: .atomic)
    }
}
