import SwiftUI

struct PastScreenCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @ObservedObject private var settings = AppSettings.shared
    let appDelegate: AppDelegate

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(NSLocalizedString("menu.capture_area", comment: "")) {
                appDelegate.takeScreenshot()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button(NSLocalizedString("menu.capture_advanced", comment: "")) {
                appDelegate.captureAdvanced()
            }
            .applyShortcut(captureAdvancedShortcut)

            Button(NSLocalizedString("menu.capture_ocr", value: "OCR 截取", comment: "")) {
                appDelegate.handleOCRHotKeyPressed()
            }
            .applyShortcut(ocrShortcut)

            Button(NSLocalizedString("menu.capture_fullscreen", comment: "")) {
                appDelegate.captureFullScreen()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandMenu("PastScreen") {
            Button(NSLocalizedString("menu.library.open", value: "打开素材库…", comment: "")) {
                openWindow(id: "capture-library")
            }
            .keyboardShortcut("l", modifiers: .command)

            Button(NSLocalizedString("tutorial.window.title", value: "使用指南", comment: "")) {
                openWindow(id: "tutorial")
            }

            Button(NSLocalizedString("onboarding.menu.show", value: "显示引导", comment: "")) {
                openWindow(id: "onboarding")
            }

            Divider()

            Button(NSLocalizedString("menu.preferences", comment: "")) {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }

    private var captureAdvancedShortcut: KeyboardShortcut? {
        keyboardShortcut(for: settings.advancedHotkey, enabled: settings.advancedHotkeyEnabled)
    }

    private var ocrShortcut: KeyboardShortcut? {
        keyboardShortcut(for: settings.ocrHotkey, enabled: settings.ocrHotkeyEnabled)
    }

    private func keyboardShortcut(for hotkey: HotKey?, enabled: Bool) -> KeyboardShortcut? {
        guard enabled, let hotkey, let chars = hotkey.characters, let first = chars.first else { return nil }
        let modifiers = eventModifiers(from: hotkey.modifierFlags)
        return KeyboardShortcut(KeyEquivalent(first), modifiers: modifiers)
    }

    private func eventModifiers(from flags: NSEvent.ModifierFlags) -> EventModifiers {
        var modifiers: EventModifiers = []
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.control) { modifiers.insert(.control) }
        return modifiers
    }
}

extension View {
    func applyShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        guard let shortcut else { return AnyView(self) }
        return AnyView(self.keyboardShortcut(shortcut))
    }
}
