import Cocoa
import Defaults
#if DEBUG
    import ScreenCaptureKit
#endif

/// Handles `pika://` URL scheme events and dispatches the corresponding app actions.
final class URLSchemeHandler: NSObject {
    static let shared = URLSchemeHandler()

    // Complexity is inherent to routing every `pika://` host to its handler; a dispatch
    // table would obscure more than it simplifies.
    // swiftlint:disable:next cyclomatic_complexity
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
        case "format": handleFormat(task: task)
        case "pick": handlePick(task: task)
        case "system": handleSystem(task: task)
        case "copy": handleCopy(task: task)
        // `#` starts a URL fragment, so `pika://set/foreground/#AABBCC` arrives with the hex
        // in `url.fragment` rather than the path.
        case "set": handleSet(task: task, hex: arg1 ?? url.fragment)
        case "history": handleHistory(task: task)
        case "window": handleWindow(task: task, arg1: arg1, arg2: arg2)
        case "appearance": handleAppearance(task: task)
        case "compliance": handleCompliance(task: task)
        case "preview": handlePreview(task: task)
        case "seed": handleSeed(url: url)
        case "swap": NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
        case "undo": NSApp.sendAction(#selector(AppDelegate.triggerUndo), to: nil, from: nil)
        case "redo": NSApp.sendAction(#selector(AppDelegate.triggerRedo), to: nil, from: nil)
        #if DEBUG
            case "debug": handleDebug(task: task, arg1: arg1, url: url)
        #endif
        default: break
        }
    }

    #if DEBUG
        /// Debug builds only:
        /// - `pika://debug/sample/<foreground|background>?x=…&y=…`: samples the screen at a point
        ///   through the Pro picker's own capture (see `debugSample`)
        /// - `pika://debug/update/<state>` and `pika://debug/update/scheduled` (Sparkle build):
        ///   checks the inline update control (see `debugUpdate`)
        private func handleDebug(task: String?, arg1: String?, url: URL) {
            switch task {
            case "sample": debugSample(arg1: arg1, url: url)
            #if TARGET_SPARKLE
                case "update": debugUpdate(arg1)
            #endif
            default: break
            }
        }

        /// Samples the screen at a point (global, top-left origin, in points, like a `CGEvent`
        /// location) through the Pro picker's own capture, and sets the colour as a pick would.
        /// Lets tests check picking accuracy without driving the mouse.
        private func debugSample(arg1: String?, url: URL) {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            func value(_ name: String) -> Double? {
                items.first { $0.name == name }?.value.flatMap(Double.init)
            }
            guard let left = value("x"), let top = value("y"),
                  let primary = NSScreen.screens.first,
                  let appDelegate = AppDelegate.shared
            else { return }
            let point = NSPoint(x: left, y: primary.frame.maxY - top)
            guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) })
            else { return }
            let eyedropper = arg1 == "background"
                ? appDelegate.eyedroppers.background
                : appDelegate.eyedroppers.foreground
            Task { @MainActor in
                guard let content = try? await SCShareableContent.current,
                      let display = content.displays.first(where: { $0.displayID == screen.displayID }),
                      case let filter = SCContentFilter(display: display, excludingWindows: []),
                      let sample = try? await PickerLoupeController.captureWindow(
                          around: point, on: screen, pixelCount: 15, filter: filter
                      ),
                      let devicePixel = sample.pixel
                else { return }
                // As a committed pick does: a flat point is read as drawn.
                var pixel = devicePixel
                if let flatPoint = sample.flatPoint,
                   let drawn = try? await PickerLoupeController.sourceColor(ofPointAt: flatPoint, filter: filter)
                {
                    pixel = drawn
                }
                ColorSpacePreference.followDisplay(screen)
                eyedropper.set(pixel)
                NotificationCenter.default.post(name: .colorPicked, object: nil)
            }
        }

        #if TARGET_SPARKLE
            /// - `<state>`: available, downloading, ready, installing, checking, uptodate, failed or
            ///   idle, with stand-in replies (see `PikaUpdateDriver.debugShow`)
            /// - `scheduled`: a real scheduled-style check against the feed now
            private func debugUpdate(_ arg1: String?) {
                // Apple events arrive on the main thread.
                MainActor.assumeIsolated {
                    guard let controller = AppDelegate.shared?.updateController, let arg1 else { return }
                    if arg1 == "scheduled" {
                        controller.updater.checkForUpdatesInBackground()
                    } else {
                        controller.driver.debugShow(arg1)
                    }
                }
            }
        #endif
    #endif

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
        } else if task == "contrast" {
            NSApp.sendAction(#selector(AppDelegate.triggerPickContrast), to: nil, from: nil)
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

    /// The colour a `pika://set` hex describes. `fromHex` accepts 3 or 6 digits with or without
    /// a leading `#` (#269). Read in the selected colour space, like a hex typed into the field,
    /// so the hex sent in is the hex shown and copied back (hard-coded sRGB drifted under the
    /// default Display P3).
    static func color(fromSetHex hex: String) -> NSColor? {
        NSColor.fromHex(hex)
    }

    private func handleSet(task: String?, hex: String?) {
        guard
            let hex,
            let color = Self.color(fromSetHex: hex),
            let appDelegate = AppDelegate.shared
        else { return }
        if task == "foreground" {
            appDelegate.eyedroppers.foreground.set(color)
        } else if task == "background" {
            appDelegate.eyedroppers.background.set(color)
        }
        appDelegate.eyedroppers.updateActiveEntry()
    }

    private func handleHistory(task: String?) {
        let visible = Defaults[.historyDrawerVisible]
        switch task {
        case "show" where !visible: Defaults[.historyDrawerVisible] = true
        case "hide" where visible: Defaults[.historyDrawerVisible] = false
        case "toggle": Defaults[.historyDrawerVisible].toggle()
        default: break
        }
    }

    private func handleWindow(task: String?, arg1: String?, arg2: String?) {
        switch task {
        case "about": NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
        case "help": NSApp.sendAction(#selector(AppDelegate.openHelpWindow), to: nil, from: nil)
        case "preferences": NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
        case "splash": NSApp.sendAction(#selector(AppDelegate.openSplashWindow), to: nil, from: nil)
        case "resize": handleWindowResize(width: arg1, height: arg2)
        default: break
        }
    }

    private func handleWindowResize(width: String?, height: String?) {
        guard
            let width, let height,
            let widthValue = Double(width), let heightValue = Double(height),
            let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })
        else { return }
        window.setContentSize(NSSize(width: widthValue, height: heightValue))
    }

    private func handleCompliance(task: String?) {
        switch task {
        case "show" where !Defaults[.showCompliance]: Defaults[.showCompliance] = true
        case "hide" where Defaults[.showCompliance]: Defaults[.showCompliance] = false
        case "toggle": Defaults[.showCompliance].toggle()
        default: break
        }
    }

    private func handlePreview(task: String?) {
        switch task {
        case "show" where !Defaults[.showColorPreview]: Defaults[.showColorPreview] = true
        case "hide" where Defaults[.showColorPreview]: Defaults[.showColorPreview] = false
        case "toggle": Defaults[.showColorPreview].toggle()
        default: break
        }
    }

    private func handleSeed(url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let filePath = components.queryItems?.first(where: { $0.name == "file" })?.value
        else { return }

        let fileURL = URL(fileURLWithPath: filePath)
        guard
            let data = try? Data(contentsOf: fileURL),
            let seed = try? JSONDecoder().decode(SeedData.self, from: data)
        else { return }

        // Build palettes: first palette is always auto-history (name = nil)
        var palettes: [Palette] = []
        let autoHistory = Palette(
            id: UUID(),
            name: nil,
            pairs: seed.history.map { $0.toColorPair() },
            createdAt: Date()
        )
        palettes.append(autoHistory)

        for seedPalette in seed.palettes ?? [] {
            let palette = Palette(
                id: UUID(),
                name: seedPalette.name,
                pairs: seedPalette.pairs.map { $0.toColorPair() },
                createdAt: Date()
            )
            palettes.append(palette)
        }

        Defaults[.palettes] = palettes
        Defaults[.activePaletteIndex] = 0
        Defaults[.undoStack] = []
        Defaults[.redoStack] = []

        // Apply the first history entry as the active colours
        if let first = autoHistory.pairs.first,
           let appDelegate = AppDelegate.shared
        {
            appDelegate.eyedroppers.foreground.set(first.foregroundColor)
            appDelegate.eyedroppers.background.set(first.backgroundColor)
            appDelegate.eyedroppers.activeHistoryID = first.id
        }
    }

    private func handleAppearance(task: String?) {
        switch task {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "system": NSApp.appearance = nil
        default: break
        }
    }
}

// MARK: - Seed data

private struct SeedData: Decodable {
    let history: [SeedPair]
    let palettes: [SeedPalette]?
}

private struct SeedPalette: Decodable {
    let name: String
    let pairs: [SeedPair]
}

private struct SeedPair: Decodable {
    let fg: String
    let bg: String

    func toColorPair() -> ColorPair {
        // Read in the selected space, like a hex sent to `pika://set`.
        guard let foreground = NSColor.fromHex(fg), let background = NSColor.fromHex(bg) else {
            return ColorPair(id: UUID(), foregroundHex: fg, backgroundHex: bg, date: Date())
        }
        return ColorPair(foreground: foreground, background: background)
    }
}
