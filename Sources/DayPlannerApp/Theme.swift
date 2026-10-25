import AppKit

enum Theme {
    static var ink: NSColor { NSColor(calibratedRed: 0.10, green: 0.28, blue: 0.32, alpha: 1) }
    static var accent: NSColor { NSColor(calibratedRed: 0.18, green: 0.55, blue: 0.52, alpha: 1) }
    static var sand: NSColor { NSColor(calibratedRed: 0.93, green: 0.86, blue: 0.72, alpha: 1) }
    static var panel: NSColor { NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.96, alpha: 0.92) }
    static var hairline: NSColor { NSColor(calibratedRed: 0.72, green: 0.80, blue: 0.78, alpha: 0.7) }
    static var muted: NSColor { NSColor(calibratedRed: 0.35, green: 0.45, blue: 0.44, alpha: 1) }

    static var brandFont: NSFont {
        NSFont(name: "Avenir Next Demi Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .semibold)
    }
    static var titleFont: NSFont {
        NSFont(name: "Avenir Next Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
    }
    static var bodyFont: NSFont {
        NSFont(name: "Avenir Next", size: 13) ?? .systemFont(ofSize: 13)
    }
    static var captionFont: NSFont {
        NSFont(name: "Avenir Next", size: 11) ?? .systemFont(ofSize: 11, weight: .regular)
    }
    static var sectionFont: NSFont {
        NSFont(name: "Avenir Next Medium", size: 11) ?? .systemFont(ofSize: 11, weight: .semibold)
    }

    static func stylePanel(_ view: NSView, radius: CGFloat = 12) {
        view.wantsLayer = true
        view.layer?.backgroundColor = panel.cgColor
        view.layer?.cornerRadius = radius
        view.layer?.borderWidth = 1
        view.layer?.borderColor = hairline.cgColor
    }

    static func primaryButton(_ title: String) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.isBordered = true
        button.setButtonType(.momentaryPushIn)
        return button
    }

    static func quietButton(_ title: String) -> NSButton {
        let button = NSButton()
        button.title = title
        // `.rounded` keeps a visible bezel; `.flexiblePush` was easy to miss in dense toolbars.
        button.bezelStyle = .rounded
        button.isBordered = true
        button.setButtonType(.momentaryPushIn)
        button.font = captionFont
        return button
    }
}
