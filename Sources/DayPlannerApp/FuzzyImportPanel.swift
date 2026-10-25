import AppKit

/// Dedicated panel for fuzzy import (more reliable than NSAlert + accessoryView).
final class FuzzyImportPanel: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var textView: NSTextView?
    private var onImport: ((String) -> Void)?

    func present(from parent: NSWindow?, onImport: @escaping (String) -> Void) {
        self.onImport = onImport

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 340),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "模糊导入今日工作"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.minSize = NSSize(width: 420, height: 280)
        panel.delegate = self
        panel.backgroundColor = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.95, alpha: 1)

        let root = NSView()
        root.translatesAutoresizingMaskIntoConstraints = false

        let heading = NSTextField(labelWithString: "粘贴或输入今天的工作描述")
        heading.font = Theme.titleFont
        heading.textColor = Theme.ink
        heading.translatesAutoresizingMaskIntoConstraints = false

        let hint = NSTextField(wrappingLabelWithString: "按换行 / 编号 / 顿号拆成任务；可用「紧急」「有空」标优先级，否则按顺序给高 / 中 / 低。")
        hint.font = Theme.captionFont
        hint.textColor = Theme.muted
        hint.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        Theme.stylePanel(scroll, radius: 8)

        let textView = NSTextView()
        textView.isRichText = false
        textView.font = Theme.bodyFont
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.string = ""
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scroll.contentSize.width, height: .greatestFiniteMagnitude)
        scroll.documentView = textView
        self.textView = textView

        let cancel = Theme.quietButton("取消")
        cancel.target = self
        cancel.action = #selector(cancelTapped)
        cancel.translatesAutoresizingMaskIntoConstraints = false

        let confirm = Theme.primaryButton("导入到所选日")
        confirm.target = self
        confirm.action = #selector(importTapped)
        confirm.translatesAutoresizingMaskIntoConstraints = false
        confirm.keyEquivalent = "\r"

        root.addSubview(heading)
        root.addSubview(hint)
        root.addSubview(scroll)
        root.addSubview(cancel)
        root.addSubview(confirm)

        let content = panel.contentView ?? NSView()
        panel.contentView = content
        content.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor),

            heading.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            heading.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),

            hint.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 6),
            hint.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            hint.trailingAnchor.constraint(equalTo: heading.trailingAnchor),

            scroll.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            scroll.bottomAnchor.constraint(equalTo: confirm.topAnchor, constant: -14),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),

            cancel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            cancel.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -14),
            confirm.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            confirm.centerYAnchor.constraint(equalTo: cancel.centerYAnchor),
            confirm.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])

        self.panel = panel
        // Use a free-floating panel (not a sheet) to avoid AppKit concurrency issues with sheet completions.
        if let parent {
            let parentFrame = parent.frame
            let size = panel.frame.size
            panel.setFrameOrigin(NSPoint(
                x: parentFrame.midX - size.width / 2,
                y: parentFrame.midY - size.height / 2
            ))
        } else {
            panel.center()
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeFirstResponder(textView)
    }

    @objc private func cancelTapped() {
        dismiss()
    }

    @objc private func importTapped() {
        let text = textView?.string ?? ""
        let callback = onImport
        dismiss()
        callback?(text)
    }

    private func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        textView = nil
        onImport = nil
    }

    func windowWillClose(_ notification: Notification) {
        panel = nil
        textView = nil
        onImport = nil
    }
}
