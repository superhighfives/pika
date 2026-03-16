import Cocoa
import Defaults

/// Handles `pika://` URL scheme events and dispatches the corresponding app actions.
final class URLSchemeHandler: NSObject {
    static let shared = URLSchemeHandler()

    @objc func handle(event: NSAppleEventDescriptor, withReplyEvent _: NSAppleEventDescriptor) {
        guard
            let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue,
            let url = URL(string: urlString),
            let scheme = url.scheme,
            let action = url.host,
            scheme.caseInsensitiveCompare("pika") == .orderedSame
        else { return }

        var list = url.pathComponents.dropFirst()
        let task = list.popFirst()
        let arg1 = list.popFirst()
        let arg2 = list.popFirst()

        if let arg1, let format = ColorFormat.withLabel(arg1) {
            Defaults[.colorFormat] = format
        }

        switch action {
        case "format":     handleFormat(task: task)
        case "pick":       handlePick(task: task)
        case "system":     handleSystem(task: task)
        case "copy":       handleCopy(task: task)
        case "set":        handleSet(task: task, hex: arg1)
        case "history":    handleHistory(task: task)
        case "window":     handleWindow(task: task, arg1: arg1, arg2: arg2)
        case "appearance": handleAppearance(task: task)
        case "swap":       NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        case "undo":       NSApp.sendAction(#selector(AppDelegate.triggerUndo), to: nil, from: nil)
        case "redo":       NSApp.sendAction(#selector(AppDelegate.triggerRedo), to: nil, from: nil)
        default: break
        }
    }

    private func handleFormat(task: String?) {
        if let task, let format = ColorFormat.withLabel(task) {
            Defaults[.colorFormat] = format
        }
    }

    private func handlePick(task: String?) {
        if task == "foreground" {
            NSApp.sendAction(#selector(AppDelegate.triggerPickForeground), to: nil, from: nil)
        } else if task == "background" {
            NSApp.sendAction(#selector(AppDelegate.triggerPickBackground), to: nil, from: nil)
        }
    }

    private func handleSystem(task: String?) {
        if task == "foreground" {
            NSApp.sendAction(#selector(AppDelegate.triggerSystemPickerForeground), to: nil, from: nil)
        } else if task == "background" {
            NSApp.sendAction(#selector(AppDelegate.triggerSystemPickerBackground), to: nil, from: nil)
        }
    }

    private func handleCopy(task: String?) {
        switch task {
        case "foreground": NSApp.sendAction(#selector(AppDelegate.triggerCopyForeground), to: nil, from: nil)
        case "background": NSApp.sendAction(#selector(AppDelegate.triggerCopyBackground), to: nil, from: nil)
        case "text": NSApp.sendAction(#selector(AppDelegate.triggerCopyText), to: nil, from: nil)
        case "json": NSApp.sendAction(#selector(AppDelegate.triggerCopyData), to: nil, from: nil)
        default: break
        }
    }

    private func handleSet(task: String?, hex: String?) {
        guard
            let hex,
            hex.count == 6,
            let appDelegate = NSApp.delegate as? AppDelegate
        else { return }
        let color = NSColor(hex: hex)
        if task == "foreground" {
            appDelegate.eyedroppers.foreground.set(color)
        } else if task == "background" {
            appDelegate.eyedroppers.background.set(color)
        }
    }

    private func handleHistory(task: String?) {
        let visible = Defaults[.historyDrawerVisible]
        switch task {
        case "show"   where !visible: Defaults[.historyDrawerVisible] = true
        case "hide"   where visible:  Defaults[.historyDrawerVisible] = false
        case "toggle": Defaults[.historyDrawerVisible].toggle()
        default: break
        }
    }

    private func handleWindow(task: String?, arg1: String?, arg2: String?) {
        switch task {
        case "about":       NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
        case "help":        NSApp.sendAction(#selector(AppDelegate.openHelpWindow), to: nil, from: nil)
        case "preferences": NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
        case "resize":      handleWindowResize(w: arg1, h: arg2)
        default: break
        }
    }

    private func handleWindowResize(w: String?, h: String?) {
        guard
            let w, let h,
            let width = Double(w), let height = Double(h),
            let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })
        else { return }
        window.setContentSize(NSSize(width: width, height: height))
    }

    private func handleAppearance(task: String?) {
        switch task {
        case "light":  NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":   NSApp.appearance = NSAppearance(named: .darkAqua)
        case "system": NSApp.appearance = nil
        default: break
        }
    }
}
