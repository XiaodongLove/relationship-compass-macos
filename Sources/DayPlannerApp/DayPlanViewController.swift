import AppKit
import DayPlannerCore

final class DayPlanViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let model: AppModel
    private let titleLabel = NSTextField(labelWithString: "")
    private let emptyLabel = NSTextField(labelWithString: "Empty Day Plan — add a task or capture to Inbox.")
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private let inboxTable = NSTableView()
    private let inboxScroll = NSScrollView()
    private var rows: [Row] = []
    private var inboxRows: [InboxItem] = []
    private var datePicker: NSDatePicker!
    private var addField: NSTextField!
    private var captureField: NSTextField!

    private enum Row {
        case event(Event)
        case open(DayPlannerCore.Task)
        case completed(DayPlannerCore.Task)
        case overdue(DayPlannerCore.Task)
        case section(String)
    }

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 720, height: 520))

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.textColor = .secondaryLabelColor

        configureTable(table)
        configureTable(inboxTable)
        scroll.documentView = table
        inboxScroll.documentView = inboxTable
        scroll.hasVerticalScroller = true
        inboxScroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        inboxScroll.translatesAutoresizingMaskIntoConstraints = false

        let todayButton = NSButton(title: "Today", target: self, action: #selector(goToday))
        todayButton.translatesAutoresizingMaskIntoConstraints = false
        let ritualButton = NSButton(title: "Planning Ritual", target: self, action: #selector(runRitual))
        ritualButton.translatesAutoresizingMaskIntoConstraints = false
        let importButton = NSButton(title: "Import Reminders", target: self, action: #selector(importReminders))
        importButton.translatesAutoresizingMaskIntoConstraints = false

        let datePicker = NSDatePicker()
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = .yearMonthDay
        datePicker.dateValue = model.selectedDay
        datePicker.target = self
        datePicker.action = #selector(dateChanged(_:))
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        self.datePicker = datePicker

        addField = makeField(placeholder: "New task for this day", action: #selector(addTask))
        let addButton = NSButton(title: "Add Task", target: self, action: #selector(addTask))
        addButton.translatesAutoresizingMaskIntoConstraints = false

        captureField = makeField(placeholder: "Quick capture to Inbox", action: #selector(capture))
        let captureButton = NSButton(title: "Capture", target: self, action: #selector(capture))
        captureButton.translatesAutoresizingMaskIntoConstraints = false

        let inboxLabel = NSTextField(labelWithString: "Inbox / Overdue")
        inboxLabel.font = .boldSystemFont(ofSize: 13)
        inboxLabel.translatesAutoresizingMaskIntoConstraints = false

        for v in [titleLabel, todayButton, ritualButton, importButton, datePicker, addField!, addButton, captureField!, captureButton, scroll, emptyLabel, inboxLabel, inboxScroll] {
            view.addSubview(v)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            todayButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            todayButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            ritualButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            ritualButton.leadingAnchor.constraint(equalTo: todayButton.trailingAnchor, constant: 8),
            importButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            importButton.leadingAnchor.constraint(equalTo: ritualButton.trailingAnchor, constant: 8),
            datePicker.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            addField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            addField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addField.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            addButton.centerYAnchor.constraint(equalTo: addField.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 88),

            captureField.topAnchor.constraint(equalTo: addField.bottomAnchor, constant: 6),
            captureField.leadingAnchor.constraint(equalTo: addField.leadingAnchor),
            captureField.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -8),
            captureButton.centerYAnchor.constraint(equalTo: captureField.centerYAnchor),
            captureButton.trailingAnchor.constraint(equalTo: addButton.trailingAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 88),

            scroll.topAnchor.constraint(equalTo: captureField.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scroll.bottomAnchor.constraint(equalTo: inboxLabel.topAnchor, constant: -8),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),

            emptyLabel.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),

            inboxLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            inboxLabel.bottomAnchor.constraint(equalTo: inboxScroll.topAnchor, constant: -4),
            inboxScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            inboxScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            inboxScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            inboxScroll.heightAnchor.constraint(equalToConstant: 140),
        ])

        model.onChange = { [weak self] in self?.reload() }
        reload()
    }

    private func configureTable(_ table: NSTableView) {
        let column = NSTableColumn(identifier: .init("main"))
        column.width = 680
        table.addTableColumn(column)
        table.headerView = nil
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 28
        table.target = self
        table.doubleAction = #selector(doubleClick(_:))
    }

    private func makeField(placeholder: String, action: Selector) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.translatesAutoresizingMaskIntoConstraints = false
        field.target = self
        field.action = action
        return field
    }

    @objc private func goToday() {
        model.selectDay(Date())
        datePicker.dateValue = model.selectedDay
    }

    @objc private func dateChanged(_ sender: NSDatePicker) {
        model.selectDay(sender.dateValue)
    }

    @objc private func addTask() {
        model.createTask(title: addField.stringValue)
        addField.stringValue = ""
    }

    @objc private func capture() {
        model.capture(title: captureField.stringValue)
        captureField.stringValue = ""
    }

    @objc private func importReminders() {
        model.importReminders()
    }

    @objc private func runRitual() {
        let alert = NSAlert()
        alert.messageText = "Planning Ritual"
        alert.informativeText = "Inbox: \(model.inbox.count) · Overdue: \(model.overdue.count)\nCommit inbox items to the selected day, or move overdue to today from the bottom list (double-click)."
        alert.addButton(withTitle: "OK")
        alert.runModal()
        model.refresh()
    }

    @objc private func doubleClick(_ sender: NSTableView) {
        if sender === inboxTable {
            let row = sender.clickedRow
            guard row >= 0 else { return }
            if row < model.inbox.count {
                model.commitInbox(model.inbox[row])
            } else {
                let overdueIndex = row - model.inbox.count
                guard overdueIndex >= 0, overdueIndex < model.overdue.count else { return }
                model.moveOverdueToToday(model.overdue[overdueIndex])
            }
        }
    }

    private func reload() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        titleLabel.stringValue = formatter.string(from: model.plan.date)

        rows = []
        if !model.overdue.isEmpty && Calendar.current.isDateInToday(model.selectedDay) {
            rows.append(.section("Overdue (triage)"))
            rows.append(contentsOf: model.overdue.map { .overdue($0) })
        }
        if !model.plan.events.isEmpty {
            rows.append(.section("Events"))
            rows.append(contentsOf: model.plan.events.map { .event($0) })
        }
        rows.append(.section("Open"))
        rows.append(contentsOf: model.plan.openTasks.map { .open($0) })
        if !model.plan.completedTasks.isEmpty {
            rows.append(.section("Completed"))
            rows.append(contentsOf: model.plan.completedTasks.map { .completed($0) })
        }

        inboxRows = model.inbox
        let empty = model.plan.openTasks.isEmpty && model.plan.completedTasks.isEmpty && model.plan.events.isEmpty
        emptyLabel.isHidden = !empty
        table.reloadData()
        inboxTable.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === inboxTable {
            return model.inbox.count + model.overdue.count
        }
        return rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView === inboxTable {
            if row < model.inbox.count {
                let item = model.inbox[row]
                return NSTextField(labelWithString: "📥 \(item.title)  (double-click → today)")
            }
            let overdue = model.overdue[row - model.inbox.count]
            return NSTextField(labelWithString: "⏰ \(overdue.title)  (double-click → today)")
        }

        switch rows[row] {
        case .section(let title):
            let label = NSTextField(labelWithString: title)
            label.font = .boldSystemFont(ofSize: 12)
            label.textColor = .secondaryLabelColor
            return label
        case .event(let event):
            let tf = DateFormatter(); tf.timeStyle = .short
            return NSTextField(labelWithString: "📅 \(event.title)  \(tf.string(from: event.start))–\(tf.string(from: event.end))")
        case .open(let task):
            return taskControl(task: task, completed: false, row: row)
        case .completed(let task):
            return taskControl(task: task, completed: true, row: row)
        case .overdue(let task):
            let button = NSButton(title: "→ Today: \(task.title)", target: self, action: #selector(promoteOverdue(_:)))
            button.tag = row
            return button
        }
    }

    private func taskControl(task: DayPlannerCore.Task, completed: Bool, row: Int) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        let check = NSButton(checkboxWithTitle: task.title, target: self, action: #selector(toggleTask(_:)))
        check.state = completed ? .on : .off
        check.tag = row
        if model.plan.softWindowOverlapHints.contains(task.id) {
            check.title = "\(task.title)  [overlap]"
        }
        stack.addArrangedSubview(check)

        if !completed {
            let soft = NSPopUpButton()
            soft.addItems(withTitles: ["Soft Window", "Morning", "Afternoon", "Evening", "Clear"])
            soft.tag = row
            soft.target = self
            soft.action = #selector(softWindowChanged(_:))
            stack.addArrangedSubview(soft)

            let back = NSButton(title: "Inbox", target: self, action: #selector(returnInbox(_:)))
            back.tag = row
            stack.addArrangedSubview(back)

            let remind = NSButton(title: "Remind +1h", target: self, action: #selector(remindHour(_:)))
            remind.tag = row
            stack.addArrangedSubview(remind)

            let up = NSButton(title: "↑", target: self, action: #selector(bumpTaskUp(_:)))
            up.tag = row
            stack.addArrangedSubview(up)
        }
        return stack
    }

    private func taskAtRow(_ row: Int) -> DayPlannerCore.Task? {
        guard row >= 0, row < rows.count else { return nil }
        switch rows[row] {
        case .open(let t), .completed(let t), .overdue(let t): return t
        default: return nil
        }
    }

    @objc private func toggleTask(_ sender: NSButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        model.toggleComplete(task)
    }

    @objc private func returnInbox(_ sender: NSButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        model.returnToInbox(task)
    }

    @objc private func softWindowChanged(_ sender: NSPopUpButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        switch sender.indexOfSelectedItem {
        case 1: model.setSoftWindow(task, .morning)
        case 2: model.setSoftWindow(task, .afternoon)
        case 3: model.setSoftWindow(task, .evening)
        case 4: model.setSoftWindow(task, nil)
        default: break
        }
    }

    @objc private func remindHour(_ sender: NSButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        model.setReminder(task, at: Date().addingTimeInterval(3600))
    }

    @objc private func bumpTaskUp(_ sender: NSButton) {
        var ids = model.plan.openTasks.map(\.id)
        guard let task = taskAtRow(sender.tag), let idx = ids.firstIndex(of: task.id), idx > 0 else { return }
        ids.swapAt(idx, idx - 1)
        model.reorderOpen(by: ids)
    }

    @objc private func promoteOverdue(_ sender: NSButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        model.moveOverdueToToday(task)
    }
}
