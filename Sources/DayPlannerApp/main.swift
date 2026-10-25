import AppKit
import Carbon
import DayPlannerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static var shared: AppDelegate?

    var window: NSWindow?
    var model: AppModel!
    var statusItem: NSStatusItem?
    var hotKeyRef: EventHotKeyRef?
    private var capturePanel: NSPanel?
    private var captureField: NSTextField?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        let model = AppModel()
        self.model = model

        let content = DayPlanViewController(model: model)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "每日工作计划"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.94, alpha: 1)
        window.minSize = NSSize(width: 640, height: 480)
        window.center()
        window.contentViewController = content
        window.makeKeyAndOrderFront(nil)
        self.window = window

        setupStatusItem()
        registerHotKey()
        model.requestSystemAccess()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "计划"
        item.button?.font = Theme.captionFont
        item.button?.toolTip = "每日工作计划 · 快速捕获"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "快速捕获…", action: #selector(showQuickCapture), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "显示今日计划", action: #selector(showWindow), keyEquivalent: "d"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showQuickCapture() {
        if capturePanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 88),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "快速捕获"
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.backgroundColor = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.95, alpha: 1)

            let root = NSView(frame: panel.contentView!.bounds)
            root.autoresizingMask = [.width, .height]
            Theme.stylePanel(root, radius: 0)

            let brand = NSTextField(labelWithString: "快速捕获到收件箱")
            brand.font = Theme.titleFont
            brand.textColor = Theme.ink
            brand.translatesAutoresizingMaskIntoConstraints = false

            let field = NSTextField()
            field.placeholderString = "想到什么，先记下来…"
            field.font = Theme.bodyFont
            field.bezelStyle = .roundedBezel
            field.isBezeled = true
            field.translatesAutoresizingMaskIntoConstraints = false
            field.target = self
            field.action = #selector(submitCapture(_:))
            captureField = field

            let button = Theme.primaryButton("添加")
            button.target = self
            button.action = #selector(submitCapture(_:))
            button.translatesAutoresizingMaskIntoConstraints = false

            root.addSubview(brand)
            root.addSubview(field)
            root.addSubview(button)
            panel.contentView = root

            NSLayoutConstraint.activate([
                brand.topAnchor.constraint(equalTo: root.topAnchor, constant: 14),
                brand.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
                field.topAnchor.constraint(equalTo: brand.bottomAnchor, constant: 8),
                field.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
                field.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -10),
                field.heightAnchor.constraint(equalToConstant: 28),
                button.centerYAnchor.constraint(equalTo: field.centerYAnchor),
                button.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            ])

            capturePanel = panel
        }
        capturePanel?.center()
        capturePanel?.makeKeyAndOrderFront(nil)
        captureField?.stringValue = ""
        if let field = captureField {
            capturePanel?.makeFirstResponder(field)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func submitCapture(_ sender: Any?) {
        guard let field = captureField else { return }
        model.capture(title: field.stringValue)
        capturePanel?.orderOut(nil)
    }

    private func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x44504C31), id: 1)
        _ = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, _) -> OSStatus in
                DispatchQueue.main.async {
                    AppDelegate.shared?.showQuickCapture()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
