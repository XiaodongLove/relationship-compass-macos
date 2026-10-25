import AppKit
import QuartzCore
import DayPlannerCore

final class DayPlanViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let model: AppModel

    private let brandLabel = NSTextField(labelWithString: "每日工作计划")
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "把今天要做的事排清楚，其余留在收件箱。")
    private let emptyTitle = NSTextField(labelWithString: "这一天还很轻")
    private let emptyBody = NSTextField(wrappingLabelWithString: "添加一条今日任务，或先捕获到收件箱，稍后再承诺进计划。")

    private let headerBar = NSView()
    private let composeBar = NSView()
    private let planPanel = NSView()
    private let inboxPanel = NSView()

    private let table = NSTableView()
    private let scroll = NSScrollView()
    private let inboxTable = NSTableView()
    private let inboxScroll = NSScrollView()
    private let inboxHeading = NSTextField(labelWithString: "收件箱 / 逾期")

    private var rows: [Row] = []
    private var datePicker: NSDatePicker!
    private var addField: NSTextField!
    private var captureField: NSTextField!
    private var gradientLayer: CAGradientLayer?

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
        let root = GradientView(frame: NSRect(x: 0, y: 0, width: 780, height: 580))
        view = root

        brandLabel.font = Theme.brandFont
        brandLabel.textColor = Theme.ink
        brandLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Theme.titleFont
        titleLabel.textColor = Theme.muted
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = Theme.captionFont
        subtitleLabel.textColor = Theme.muted
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        emptyTitle.font = Theme.titleFont
        emptyTitle.textColor = Theme.ink
        emptyTitle.alignment = .center
        emptyTitle.translatesAutoresizingMaskIntoConstraints = false

        emptyBody.font = Theme.bodyFont
        emptyBody.textColor = Theme.muted
        emptyBody.alignment = .center
        emptyBody.maximumNumberOfLines = 3
        emptyBody.translatesAutoresizingMaskIntoConstraints = false

        Theme.stylePanel(planPanel)
        Theme.stylePanel(inboxPanel)
        planPanel.translatesAutoresizingMaskIntoConstraints = false
        inboxPanel.translatesAutoresizingMaskIntoConstraints = false
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        composeBar.translatesAutoresizingMaskIntoConstraints = false

        configureTable(table, rowHeight: 36)
        configureTable(inboxTable, rowHeight: 32)
        styleScroll(scroll, document: table)
        styleScroll(inboxScroll, document: inboxTable)

        let todayButton = Theme.quietButton("今天")
        todayButton.target = self
        todayButton.action = #selector(goToday)
        todayButton.translatesAutoresizingMaskIntoConstraints = false
        let ritualButton = Theme.quietButton("日计划仪式")
        ritualButton.target = self
        ritualButton.action = #selector(runRitual)
        ritualButton.translatesAutoresizingMaskIntoConstraints = false
        let importButton = Theme.quietButton("导入提醒事项")
        importButton.target = self
        importButton.action = #selector(importReminders)
        importButton.translatesAutoresizingMaskIntoConstraints = false
        let fuzzyButton = Theme.quietButton("模糊导入")
        fuzzyButton.target = self
        fuzzyButton.action = #selector(showFuzzyImport)
        fuzzyButton.translatesAutoresizingMaskIntoConstraints = false

        let datePicker = NSDatePicker()
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerElements = .yearMonthDay
        datePicker.dateValue = model.selectedDay
        datePicker.target = self
        datePicker.action = #selector(dateChanged(_:))
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.font = Theme.captionFont
        self.datePicker = datePicker

        addField = makeField(placeholder: "为当天新建任务", action: #selector(addTask))
        let addButton = Theme.primaryButton("添加任务")
        addButton.target = self
        addButton.action = #selector(addTask)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        captureField = makeField(placeholder: "快速捕获到收件箱", action: #selector(capture))
        let captureButton = Theme.quietButton("捕获")
        captureButton.target = self
        captureButton.action = #selector(capture)
        captureButton.translatesAutoresizingMaskIntoConstraints = false

        inboxHeading.font = Theme.sectionFont
        inboxHeading.textColor = Theme.ink
        inboxHeading.translatesAutoresizingMaskIntoConstraints = false

        let toolStack = NSStackView(views: [todayButton, ritualButton, fuzzyButton, importButton, datePicker])
        toolStack.orientation = .horizontal
        toolStack.spacing = 8
        toolStack.alignment = .centerY
        toolStack.translatesAutoresizingMaskIntoConstraints = false

        headerBar.addSubview(brandLabel)
        headerBar.addSubview(titleLabel)
        headerBar.addSubview(subtitleLabel)
        headerBar.addSubview(toolStack)

        composeBar.addSubview(addField)
        composeBar.addSubview(addButton)
        composeBar.addSubview(captureField)
        composeBar.addSubview(captureButton)

        planPanel.addSubview(scroll)
        planPanel.addSubview(emptyTitle)
        planPanel.addSubview(emptyBody)

        inboxPanel.addSubview(inboxHeading)
        inboxPanel.addSubview(inboxScroll)

        view.addSubview(headerBar)
        view.addSubview(composeBar)
        view.addSubview(planPanel)
        view.addSubview(inboxPanel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            brandLabel.topAnchor.constraint(equalTo: headerBar.topAnchor),
            brandLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),

            titleLabel.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),

            toolStack.centerYAnchor.constraint(equalTo: brandLabel.centerYAnchor),
            toolStack.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),

            composeBar.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 16),
            composeBar.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            composeBar.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            composeBar.heightAnchor.constraint(equalToConstant: 72),

            addField.topAnchor.constraint(equalTo: composeBar.topAnchor),
            addField.leadingAnchor.constraint(equalTo: composeBar.leadingAnchor),
            addField.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -10),
            addField.heightAnchor.constraint(equalToConstant: 30),
            addButton.centerYAnchor.constraint(equalTo: addField.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: composeBar.trailingAnchor),
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),

            captureField.topAnchor.constraint(equalTo: addField.bottomAnchor, constant: 8),
            captureField.leadingAnchor.constraint(equalTo: addField.leadingAnchor),
            captureField.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -10),
            captureField.heightAnchor.constraint(equalToConstant: 30),
            captureButton.centerYAnchor.constraint(equalTo: captureField.centerYAnchor),
            captureButton.trailingAnchor.constraint(equalTo: composeBar.trailingAnchor),
            captureButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),

            planPanel.topAnchor.constraint(equalTo: composeBar.bottomAnchor, constant: 14),
            planPanel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            planPanel.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            planPanel.bottomAnchor.constraint(equalTo: inboxPanel.topAnchor, constant: -14),

            scroll.topAnchor.constraint(equalTo: planPanel.topAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: planPanel.leadingAnchor, constant: 10),
            scroll.trailingAnchor.constraint(equalTo: planPanel.trailingAnchor, constant: -10),
            scroll.bottomAnchor.constraint(equalTo: planPanel.bottomAnchor, constant: -10),

            emptyTitle.centerXAnchor.constraint(equalTo: planPanel.centerXAnchor),
            emptyTitle.centerYAnchor.constraint(equalTo: planPanel.centerYAnchor, constant: -14),
            emptyBody.topAnchor.constraint(equalTo: emptyTitle.bottomAnchor, constant: 8),
            emptyBody.centerXAnchor.constraint(equalTo: planPanel.centerXAnchor),
            emptyBody.widthAnchor.constraint(lessThanOrEqualToConstant: 320),

            inboxPanel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
            inboxPanel.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
            inboxPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            inboxPanel.heightAnchor.constraint(equalToConstant: 156),

            inboxHeading.topAnchor.constraint(equalTo: inboxPanel.topAnchor, constant: 12),
            inboxHeading.leadingAnchor.constraint(equalTo: inboxPanel.leadingAnchor, constant: 14),

            inboxScroll.topAnchor.constraint(equalTo: inboxHeading.bottomAnchor, constant: 6),
            inboxScroll.leadingAnchor.constraint(equalTo: inboxPanel.leadingAnchor, constant: 10),
            inboxScroll.trailingAnchor.constraint(equalTo: inboxPanel.trailingAnchor, constant: -10),
            inboxScroll.bottomAnchor.constraint(equalTo: inboxPanel.bottomAnchor, constant: -10),
        ])

        model.onChange = { [weak self] in self?.reload() }
        reload()
    }

    private func configureTable(_ table: NSTableView, rowHeight: CGFloat) {
        let column = NSTableColumn(identifier: .init("main"))
        column.width = 700
        table.addTableColumn(column)
        table.headerView = nil
        table.dataSource = self
        table.delegate = self
        table.rowHeight = rowHeight
        table.backgroundColor = .clear
        table.selectionHighlightStyle = .none
        table.intercellSpacing = NSSize(width: 0, height: 4)
        table.target = self
        table.doubleAction = #selector(doubleClick(_:))
        if #available(macOS 11.0, *) {
            table.style = .plain
        }
    }

    private func styleScroll(_ scroll: NSScrollView, document: NSTableView) {
        scroll.documentView = document
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = NSEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
    }

    private func makeField(placeholder: String, action: Selector) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.font = Theme.bodyFont
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.focusRingType = .default
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

    @objc private func showFuzzyImport() {
        let alert = NSAlert()
        alert.messageText = "模糊导入今日工作"
        alert.informativeText = "粘贴一段对今天工作的描述。将按换行/编号/顿号拆成任务，并根据「紧急/有空」等词或出现顺序给出高/中/低优先级。"
        alert.addButton(withTitle: "导入到所选日")
        alert.addButton(withTitle: "取消")

        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 420, height: 160))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let textView = NSTextView(frame: scroll.bounds)
        textView.isRichText = false
        textView.font = Theme.bodyFont
        textView.string = ""
        textView.autoresizingMask = [.width, .height]
        scroll.documentView = textView
        alert.accessoryView = scroll

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        let text = textView.string
        let created = model.importFuzzyDescription(text)
        if created.isEmpty {
            let tip = NSAlert()
            tip.messageText = "没有识别到任务"
            tip.informativeText = "试试换行分条，或写「1. … 2. …」。也可用「紧急」「有空」标优先级。"
            tip.addButton(withTitle: "好")
            tip.runModal()
        }
    }

    @objc private func runRitual() {
        let alert = NSAlert()
        alert.messageText = "日计划仪式"
        alert.informativeText = "收件箱：\(model.inbox.count) · 逾期：\(model.overdue.count)\n可将收件箱条目承诺到所选日期；底部列表双击可把逾期任务挪到今天。"
        alert.addButton(withTitle: "好")
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .full
        titleLabel.stringValue = formatter.string(from: model.plan.date)

        rows = []
        if !model.overdue.isEmpty && Calendar.current.isDateInToday(model.selectedDay) {
            rows.append(.section("逾期 · 待分拣"))
            rows.append(contentsOf: model.overdue.map { .overdue($0) })
        }
        if !model.plan.events.isEmpty {
            rows.append(.section("日程"))
            rows.append(contentsOf: model.plan.events.map { .event($0) })
        }
        rows.append(.section("进行中"))
        rows.append(contentsOf: model.plan.openTasks.map { .open($0) })
        if !model.plan.completedTasks.isEmpty {
            rows.append(.section("已完成"))
            rows.append(contentsOf: model.plan.completedTasks.map { .completed($0) })
        }

        let empty = model.plan.openTasks.isEmpty && model.plan.completedTasks.isEmpty && model.plan.events.isEmpty
            && !(Calendar.current.isDateInToday(model.selectedDay) && !model.overdue.isEmpty)
        emptyTitle.isHidden = !empty
        emptyBody.isHidden = !empty
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
            return inboxRowView(row: row)
        }

        switch rows[row] {
        case .section(let title):
            return sectionLabel(title)
        case .event(let event):
            let tf = DateFormatter()
            tf.locale = Locale(identifier: "zh_CN")
            tf.timeStyle = .short
            let label = NSTextField(labelWithString: "\(event.title)    \(tf.string(from: event.start)) – \(tf.string(from: event.end))")
            label.font = Theme.bodyFont
            label.textColor = Theme.muted
            return label
        case .open(let task):
            return taskControl(task: task, completed: false, row: row)
        case .completed(let task):
            return taskControl(task: task, completed: true, row: row)
        case .overdue(let task):
            let button = Theme.quietButton("挪到今天 · \(task.title)")
            button.target = self
            button.action = #selector(promoteOverdue(_:))
            button.tag = row
            button.font = Theme.bodyFont
            return button
        }
    }

    private func inboxRowView(row: Int) -> NSView {
        let wrap = NSView()
        wrap.wantsLayer = true
        wrap.layer?.cornerRadius = 8
        wrap.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.45).cgColor

        let label = NSTextField(labelWithString: "")
        label.font = Theme.bodyFont
        label.textColor = Theme.ink
        label.translatesAutoresizingMaskIntoConstraints = false
        let hint = NSTextField(labelWithString: "")
        hint.font = Theme.captionFont
        hint.textColor = Theme.muted
        hint.translatesAutoresizingMaskIntoConstraints = false

        if row < model.inbox.count {
            label.stringValue = model.inbox[row].title
            hint.stringValue = "双击承诺到所选日"
        } else {
            let overdue = model.overdue[row - model.inbox.count]
            label.stringValue = overdue.title
            hint.stringValue = "逾期 · 双击挪到今天"
            wrap.layer?.backgroundColor = Theme.sand.withAlphaComponent(0.35).cgColor
        }

        wrap.addSubview(label)
        wrap.addSubview(hint)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 10),
            label.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            hint.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -10),
            hint.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: hint.leadingAnchor, constant: -8),
            wrap.heightAnchor.constraint(equalToConstant: 28),
        ])
        return wrap
    }

    private func sectionLabel(_ title: String) -> NSView {
        let label = NSTextField(labelWithString: title.uppercased(with: Locale(identifier: "zh_CN")))
        // Keep Chinese as-is; uppercased is no-op for CJK
        label.stringValue = title
        label.font = Theme.sectionFont
        label.textColor = Theme.accent
        return label
    }

    private func taskControl(task: DayPlannerCore.Task, completed: Bool, row: Int) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY

        let badge = NSTextField(labelWithString: priorityLabel(task.priority))
        badge.font = Theme.captionFont
        badge.textColor = priorityColor(task.priority)
        badge.setContentHuggingPriority(.required, for: .horizontal)
        stack.addArrangedSubview(badge)

        let check = NSButton(checkboxWithTitle: task.title, target: self, action: #selector(toggleTask(_:)))
        check.font = Theme.bodyFont
        check.state = completed ? .on : .off
        check.tag = row
        if completed {
            check.contentTintColor = Theme.muted
        }
        if model.plan.softWindowOverlapHints.contains(task.id) {
            check.title = "\(task.title)  · 与日程重叠"
        }
        stack.addArrangedSubview(check)
        check.setContentHuggingPriority(.defaultLow, for: .horizontal)

        if !completed {
            let priorityMenu = NSPopUpButton()
            priorityMenu.font = Theme.captionFont
            priorityMenu.addItems(withTitles: ["优先级", "高", "中", "低"])
            switch task.priority {
            case .high: priorityMenu.selectItem(at: 1)
            case .medium: priorityMenu.selectItem(at: 2)
            case .low: priorityMenu.selectItem(at: 3)
            }
            priorityMenu.tag = row
            priorityMenu.target = self
            priorityMenu.action = #selector(priorityChanged(_:))
            stack.addArrangedSubview(priorityMenu)

            let soft = NSPopUpButton()
            soft.font = Theme.captionFont
            soft.addItems(withTitles: ["软时段", "上午", "下午", "晚上", "清除"])
            soft.tag = row
            soft.target = self
            soft.action = #selector(softWindowChanged(_:))
            soft.setContentHuggingPriority(.required, for: .horizontal)
            stack.addArrangedSubview(soft)

            let back = Theme.quietButton("收件箱")
            back.target = self
            back.action = #selector(returnInbox(_:))
            back.tag = row
            stack.addArrangedSubview(back)

            let remind = Theme.quietButton("+1小时")
            remind.target = self
            remind.action = #selector(remindHour(_:))
            remind.tag = row
            stack.addArrangedSubview(remind)

            let up = Theme.quietButton("上移")
            up.target = self
            up.action = #selector(bumpTaskUp(_:))
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

    @objc private func priorityChanged(_ sender: NSPopUpButton) {
        guard let task = taskAtRow(sender.tag) else { return }
        switch sender.indexOfSelectedItem {
        case 1: model.setPriority(task, .high)
        case 2: model.setPriority(task, .medium)
        case 3: model.setPriority(task, .low)
        default: break
        }
    }

    private func priorityLabel(_ priority: Priority) -> String {
        switch priority {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }

    private func priorityColor(_ priority: Priority) -> NSColor {
        switch priority {
        case .high: return NSColor(calibratedRed: 0.75, green: 0.28, blue: 0.22, alpha: 1)
        case .medium: return Theme.accent
        case .low: return Theme.muted
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

final class GradientView: NSView {
    private let gradient = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        gradient.colors = [
            NSColor(calibratedRed: 0.90, green: 0.95, blue: 0.94, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.89, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.88, green: 0.93, blue: 0.96, alpha: 1).cgColor,
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0.05, y: 1)
        gradient.endPoint = CGPoint(x: 0.95, y: 0)
        layer = CALayer()
        layer?.addSublayer(gradient)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        gradient.frame = bounds
    }
}
