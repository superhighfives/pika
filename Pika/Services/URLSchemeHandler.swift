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
        let colorFormat = list.popFirst()

        if let colorFormat, let format = ColorFormat.withLabel(colorFormat) {
            Defaults[.colorFormat] = format
        }

        switch action {
        case "format": handleFormat(task: task)
        case "pick": handlePick(task: task)
        case "system": handleSystem(task: task)
        case "copy": handleCopy(task: task)
        case "swap": NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        case "undo": NSApp.sendAction(#selector(AppDelegate.triggerUndo), to: nil, from: nil)
        case "redo": NSApp.sendAction(#selector(AppDelegate.triggerRedo), to: nil, from: nil)
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
}
