import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground = Eyedropper(
        type: .foreground, color: PikaConstants.initialColors.randomElement()!
    )
    @Published var background = Eyedropper(type: .background, color: NSColor.black)
    @Published var activeHistoryID: UUID?

    private func pushUndo() {
        var stack = Defaults[.undoStack]
        stack.insert(Defaults[.colorHistory], at: 0)
        if stack.count > ColorPair.maxHistory {
            stack = Array(stack.prefix(ColorPair.maxHistory))
        }
        Defaults[.undoStack] = stack
        Defaults[.redoStack] = []
    }

    private var activeIndex: Int {
        let history = Defaults[.colorHistory]
        if let id = activeHistoryID,
           let index = history.firstIndex(where: { $0.id == id })
        {
            return index
        }
        return 0
    }

    func recordHistory() {
        let fgHex = foreground.color.toHexString()
        let bgHex = background.color.toHexString()

        let history = Defaults[.colorHistory]
        if let last = history.first, last.foregroundHex == fgHex, last.backgroundHex == bgHex {
            return
        }

        if !history.isEmpty { pushUndo() }
        let pair = ColorPair(id: UUID(), foregroundHex: fgHex, backgroundHex: bgHex, date: Date())
        var updated = [pair] + history
        if updated.count > ColorPair.maxHistory {
            updated = Array(updated.prefix(ColorPair.maxHistory))
        }
        Defaults[.colorHistory] = updated
        activeHistoryID = pair.id
    }

    func swap() {
        pushUndo()
        let temp = foreground.color
        foreground.color = background.color
        background.color = temp

        var history = Defaults[.colorHistory]
        guard !history.isEmpty else { return }
        let index = activeIndex
        let entry = history[index]
        history[index] = ColorPair(
            id: entry.id,
            foregroundHex: entry.backgroundHex,
            backgroundHex: entry.foregroundHex,
            date: entry.date
        )
        Defaults[.colorHistory] = history
    }

    func undo() {
        var undoStack = Defaults[.undoStack]
        guard !undoStack.isEmpty else { return }
        let current = Defaults[.colorHistory]
        let snapshot = undoStack.removeFirst()
        Defaults[.undoStack] = undoStack
        var redoStack = Defaults[.redoStack]
        redoStack.insert(current, at: 0)
        Defaults[.redoStack] = redoStack
        Defaults[.colorHistory] = snapshot
        applyRestoredSnapshot(snapshot, previous: current)
    }

    func redo() {
        var redoStack = Defaults[.redoStack]
        guard !redoStack.isEmpty else { return }
        let current = Defaults[.colorHistory]
        let snapshot = redoStack.removeFirst()
        Defaults[.redoStack] = redoStack
        var undoStack = Defaults[.undoStack]
        undoStack.insert(current, at: 0)
        Defaults[.undoStack] = undoStack
        Defaults[.colorHistory] = snapshot
        applyRestoredSnapshot(snapshot, previous: current)
    }

    private func applyRestoredSnapshot(_ snapshot: [ColorPair], previous: [ColorPair]) {
        let previousIDs = Set(previous.map(\.id))
        if let restored = snapshot.first(where: { !previousIDs.contains($0.id) }) {
            applyHistoryEntry(restored)
        } else if let first = snapshot.first {
            applyHistoryEntry(first)
        }
    }

    func clearHistory() {
        pushUndo()
        foreground.color = PikaConstants.initialColors.randomElement()!
        background.color = NSColor.black
        let pair = ColorPair(
            id: UUID(),
            foregroundHex: foreground.color.toHexString(),
            backgroundHex: background.color.toHexString(),
            date: Date()
        )
        Defaults[.colorHistory] = [pair]
        activeHistoryID = pair.id
    }

    func deleteCurrentHistoryEntry() {
        var history = Defaults[.colorHistory]

        if history.count <= 1 {
            clearHistory()
            return
        }

        let index = activeIndex

        pushUndo()
        history.remove(at: index)
        Defaults[.colorHistory] = history

        let newIndex = index > 0 ? index - 1 : 0
        applyHistoryEntry(history[newIndex])
    }

    func deleteHistoryEntry(id: UUID) {
        var history = Defaults[.colorHistory]

        if history.count <= 1 {
            clearHistory()
            return
        }

        guard let index = history.firstIndex(where: { $0.id == id }) else { return }

        let isActive = id == activeHistoryID

        pushUndo()
        history.remove(at: index)
        Defaults[.colorHistory] = history

        if isActive {
            let newIndex = index > 0 ? index - 1 : 0
            applyHistoryEntry(history[newIndex])
        }
    }

    func navigatePrevious() {
        let history = Defaults[.colorHistory]
        guard history.count > 1 else { return }
        let nextIndex = activeIndex + 1
        guard nextIndex < history.count else { return }
        applyHistoryEntry(history[nextIndex])
    }

    func navigateNext() {
        let history = Defaults[.colorHistory]
        guard history.count > 1 else { return }
        let nextIndex = activeIndex - 1
        guard nextIndex >= 0 else { return }
        applyHistoryEntry(history[nextIndex])
    }

    func applyHistoryEntry(_ pair: ColorPair) {
        foreground.color = pair.foregroundColor
        background.color = pair.backgroundColor
        activeHistoryID = pair.id
    }
}

class Eyedropper: ObservableObject {
    enum Types: String, CustomStringConvertible {
        case foreground
        case background

        var description: String {
            switch self {
            case .foreground: return PikaText.textColorForeground
            case .background: return PikaText.textColorBackground
            }
        }

        var copySelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerCopyForeground)
            case .background: return #selector(AppDelegate.triggerCopyBackground)
            }
        }

        var pickSelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerPickForeground)
            case .background: return #selector(AppDelegate.triggerPickBackground)
            }
        }

        var systemPickerSelector: Selector {
            switch self {
            case .foreground: return #selector(AppDelegate.triggerSystemPickerForeground)
            case .background: return #selector(AppDelegate.triggerSystemPickerBackground)
            }
        }

        var pickNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerPickForeground
            case .background: return .triggerPickBackground
            }
        }

        var copyNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerCopyForeground
            case .background: return .triggerCopyBackground
            }
        }

        var systemPickerNotification: Notification.Name {
            switch self {
            case .foreground: return .triggerSystemPickerForeground
            case .background: return .triggerSystemPickerBackground
            }
        }
    }

    let type: Types
    var forceShow = false

    let colorNames: [ColorName] = loadColors()!
    var closestVector: ClosestVector!

    @objc @Published public var color: NSColor

    private var overlayWindow = ColorPickOverlayWindow()

    init(type: Types, color: NSColor) {
        self.type = type
        self.color = color.usingColorSpace(.sRGB) ?? color

        // Load colors
        closestVector = ClosestVector(colorNames.map { $0.color.toRGB8BitArray() })
    }

    func getClosestColor() -> String {
        colorNames[closestVector.compare(color)].name
    }

    func set(_ selectedColor: NSColor) {
        color = selectedColor.usingColorSpace(.sRGB) ?? selectedColor
    }

    @objc func colorDidChange(sender: AnyObject) {
        if let picker = sender as? NSColorPanel {
            guard let srgbColor = picker.color.usingColorSpace(.sRGB) else { return }
            color = srgbColor
        }
    }

    func picker() {
        let panel = NSColorPanel.shared
        panel.showsAlpha = false
        panel.title = "\(type.rawValue.capitalized)"
        panel.titleVisibility = .visible
        panel.setTarget(self)
        panel.color = color
        panel.mode = .RGB
        panel.colorSpace = Defaults[.colorSpace]
        panel.orderFrontRegardless()
        panel.setAction(#selector(colorDidChange))
        panel.isContinuous = true
    }

    func start() {
        if Defaults[.hidePikaWhilePicking] {
            if NSApp.mainWindow?.isVisible == true {
                forceShow = true
            }
            NSApp.sendAction(#selector(AppDelegate.hidePika), to: nil, from: nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let sampler = NSColorSampler()
            sampler.show { selectedColor in

                if let selectedColor = selectedColor {
                    let normalizedColor = selectedColor.usingColorSpace(.sRGB) ?? selectedColor

                    if Defaults[.showColorOverlay] {
                        let colorText = normalizedColor.toFormat(
                            format: Defaults[.colorFormat], style: Defaults[.copyFormat]
                        )
                        let cursorPosition = NSEvent.mouseLocation
                        self.overlayWindow.show(
                            colorText: colorText,
                            pickedColor: normalizedColor,
                            nearCursor: cursorPosition,
                            duration: Defaults[.colorOverlayDuration]
                        )
                    }

                    self.set(normalizedColor)

                    NotificationCenter.default.post(name: .colorPicked, object: nil)

                    if Defaults[.copyColorOnPick] {
                        NSApp.sendAction(self.type.copySelector, to: nil, from: nil)
                    } else {
                        NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                    }
                }

                if self.forceShow {
                    self.forceShow = false
                    NSApp.sendAction(#selector(AppDelegate.showPika), to: nil, from: nil)
                }

                let panel = NSColorPanel.shared
                if panel.isVisible {
                    self.picker()
                }
            }
        }
    }
}
