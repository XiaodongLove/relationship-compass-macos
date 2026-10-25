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

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        let model = AppModel()
        self.model = model

        let content = DayPlanViewController(model: model)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Day Planner"
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
        item.button?.title = "DP"
        item.button?.toolTip = "Day Planner Quick Capture"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quick Capture…", action: #selector(showQuickCapture), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Show Day Plan", action: #selector(showWindow), keyEquivalent: "d"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
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
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 56),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "Quick Capture"
            panel.isFloatingPanel = true
            panel.level = .floating
            let field = NSTextField(frame: NSRect(x: 12, y: 16, width: 260, height: 24))
            field.placeholderString = "Inbox item"
            field.tag = 42
            let button = NSButton(frame: NSRect(x: 280, y: 12, width: 64, height: 28))
            button.title = "Add"
            button.target = self
            button.action = #selector(submitCapture(_:))
            panel.contentView?.addSubview(field)
            panel.contentView?.addSubview(button)
            capturePanel = panel
        }
        capturePanel?.center()
        capturePanel?.makeKeyAndOrderFront(nil)
        if let field = capturePanel?.contentView?.viewWithTag(42) as? NSTextField {
            field.stringValue = ""
            capturePanel?.makeFirstResponder(field)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func submitCapture(_ sender: Any?) {
        guard let field = capturePanel?.contentView?.viewWithTag(42) as? NSTextField else { return }
        model.capture(title: field.stringValue)
        capturePanel?.orderOut(nil)
    }

    private func registerHotKey() {
        // Control+Option+Space → Quick Capture
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
