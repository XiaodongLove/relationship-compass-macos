import AppKit
import DayPlannerCore

final class DayPlanViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let model: AppModel
    private let titleLabel = NSTextField(labelWithString: "")
    private let emptyLabel = NSTextField(labelWithString: "Empty Day Plan — no tasks or events for this day yet.")
    private let table = NSTableView()
    private let scroll = NSScrollView()
    private var rows: [Row] = []

    private enum Row {
        case event(Event)
        case open(DayPlannerCore.Task)
        case completed(DayPlannerCore.Task)
        case section(String)
    }

    init(model: AppModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center

        let column = NSTableColumn(identifier: .init("main"))
        column.title = "Day Plan"
        column.width = 600
        table.addTableColumn(column)
        table.headerView = nil
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 28
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        let todayButton = NSButton(title: "Today", target: self, action: #selector(goToday))
        todayButton.translatesAutoresizingMaskIntoConstraints = false

        let datePicker = NSDatePicker()
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = .yearMonthDay
        datePicker.dateValue = model.selectedDay
        datePicker.target = self
        datePicker.action = #selector(dateChanged(_:))
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.identifier = .init("dayPicker")
        self.datePicker = datePicker

        view.addSubview(titleLabel)
        view.addSubview(todayButton)
        view.addSubview(datePicker)
        view.addSubview(scroll)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            todayButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            todayButton.trailingAnchor.constraint(equalTo: datePicker.leadingAnchor, constant: -8),
            datePicker.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scroll.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        model.onChange = { [weak self] in self?.reload() }
        reload()
    }

    private var datePicker: NSDatePicker!

    @objc private func goToday() {
        model.selectDay(Date())
        datePicker.dateValue = model.selectedDay
    }

    @objc private func dateChanged(_ sender: NSDatePicker) {
        model.selectDay(sender.dateValue)
    }

    private func reload() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        titleLabel.stringValue = formatter.string(from: model.plan.date)

        rows = []
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

        let empty = model.plan.openTasks.isEmpty && model.plan.completedTasks.isEmpty && model.plan.events.isEmpty
        emptyLabel.isHidden = !empty
        scroll.isHidden = empty
        table.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let label = NSTextField(labelWithString: "")
        switch rows[row] {
        case .section(let title):
            label.stringValue = title
            label.font = .boldSystemFont(ofSize: 12)
            label.textColor = .secondaryLabelColor
        case .event(let event):
            let tf = DateFormatter()
            tf.timeStyle = .short
            label.stringValue = "\(event.title)  \(tf.string(from: event.start))–\(tf.string(from: event.end))"
        case .open(let task):
            var text = "○ \(task.title)"
            if model.plan.softWindowOverlapHints.contains(task.id) {
                text += "  [overlap]"
            }
            label.stringValue = text
        case .completed(let task):
            label.stringValue = "✓ \(task.title)"
            label.textColor = .secondaryLabelColor
        }
        return label
    }
}
