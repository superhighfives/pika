import Defaults
import SwiftUI

class Eyedroppers: ObservableObject {
    @Default(.colorFormat) var colorFormat

    @Published var foreground: Eyedropper
    @Published var background: Eyedropper
    @Published var activeHistoryID: UUID?
    private var lastAutoHistoryID: UUID?

    init() {
        if let latest = Defaults[.palettes].first?.pairs.first {
            foreground = Eyedropper(type: .foreground, color: latest.foregroundColor)
            background = Eyedropper(type: .background, color: latest.backgroundColor)
            activeHistoryID = latest.id
        } else {
            foreground = Eyedropper(type: .foreground, color: PikaConstants.initialColors.randomElement()!)
            background = Eyedropper(type: .background, color: NSColor.black)
        }
    }

    // MARK: - History helpers

    private var autoHistory: [ColorPair] {
        get { Defaults[.palettes].first?.pairs ?? [] }
        set {
            var palettes = Defaults[.palettes]
            guard !palettes.isEmpty else { return }
            palettes[0].pairs = newValue
            Defaults[.palettes] = palettes
        }
    }

    private func pushUndo() {
        var stack = Defaults[.undoStack]
        stack.insert(autoHistory, at: 0)
        if stack.count > ColorPair.maxHistory {
            stack = Array(stack.prefix(ColorPair.maxHistory))
        }
        Defaults[.undoStack] = stack
        Defaults[.redoStack] = []
    }

    private var activePairs: [ColorPair] {
        let palettes = Defaults[.palettes]
        let idx = Defaults[.activePaletteIndex]
        guard idx >= 0, idx < palettes.count else { return autoHistory }
        return palettes[idx].pairs
    }

    private var activeIndex: Int {
        let pairs = activePairs
        if let id = activeHistoryID,
           let index = pairs.firstIndex(where: { $0.id == id })
        {
            return index
        }
        return 0
    }

    func updateActiveEntry() {
        let fgHex = foreground.color.toHexString()
        let bgHex = background.color.toHexString()

        let paletteIndex = Defaults[.activePaletteIndex]
        var palettes = Defaults[.palettes]
        guard paletteIndex >= 0, paletteIndex < palettes.count,
              let id = activeHistoryID,
              let index = palettes[paletteIndex].pairs.firstIndex(where: { $0.id == id })
        else { return }

        let entry = palettes[paletteIndex].pairs[index]
        if entry.foregroundHex == fgHex, entry.backgroundHex == bgHex { return }

        palettes[paletteIndex].pairs[index] = ColorPair(
            id: entry.id,
            foregroundHex: fgHex,
            backgroundHex: bgHex,
            date: entry.date
        )
        Defaults[.palettes] = palettes
    }

    func recordHistory() {
        let fgHex = foreground.color.toHexString()
        let bgHex = background.color.toHexString()

        let history = autoHistory
        if let last = history.first, last.foregroundHex == fgHex, last.backgroundHex == bgHex {
            return
        }

        if !history.isEmpty { pushUndo() }
        let pair = ColorPair(id: UUID(), foregroundHex: fgHex, backgroundHex: bgHex, date: Date())
        var updated = [pair] + history
        if updated.count > ColorPair.maxHistory {
            updated = Array(updated.prefix(ColorPair.maxHistory))
        }
        autoHistory = updated
        activeHistoryID = pair.id
    }

    func swap() {
        let paletteIndex = Defaults[.activePaletteIndex]
        if paletteIndex == 0 { pushUndo() }
        let temp = foreground.color
        foreground.color = background.color
        background.color = temp
        var palettes = Defaults[.palettes]
        guard paletteIndex >= 0, paletteIndex < palettes.count else { return }

        guard let id = activeHistoryID,
              let index = palettes[paletteIndex].pairs.firstIndex(where: { $0.id == id })
        else { return }

        let entry = palettes[paletteIndex].pairs[index]
        palettes[paletteIndex].pairs[index] = ColorPair(
            id: entry.id,
            foregroundHex: entry.backgroundHex,
            backgroundHex: entry.foregroundHex,
            date: entry.date
        )
        Defaults[.palettes] = palettes
    }

    func undo() {
        var undoStack = Defaults[.undoStack]
        guard !undoStack.isEmpty else { return }
        let current = autoHistory
        let snapshot = undoStack.removeFirst()
        Defaults[.undoStack] = undoStack
        var redoStack = Defaults[.redoStack]
        redoStack.insert(current, at: 0)
        Defaults[.redoStack] = redoStack
        autoHistory = snapshot
        applyRestoredSnapshot(snapshot, previous: current)
    }

    func redo() {
        var redoStack = Defaults[.redoStack]
        guard !redoStack.isEmpty else { return }
        let current = autoHistory
        let snapshot = redoStack.removeFirst()
        Defaults[.redoStack] = redoStack
        var undoStack = Defaults[.undoStack]
        undoStack.insert(current, at: 0)
        Defaults[.undoStack] = undoStack
        autoHistory = snapshot
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
        autoHistory = [pair]
        activeHistoryID = pair.id
    }

    func deleteCurrentEntry() {
        let paletteIndex = Defaults[.activePaletteIndex]
        if paletteIndex == 0 {
            deleteCurrentHistoryEntry()
        } else if let id = activeHistoryID {
            deleteChipFromPalette(paletteIndex: paletteIndex, pairID: id)
            let palettes = Defaults[.palettes]
            if paletteIndex < palettes.count, let first = palettes[paletteIndex].pairs.first {
                applyEntry(first)
            }
        }
    }

    func deleteCurrentHistoryEntry() {
        var history = autoHistory

        if history.count <= 1 {
            clearHistory()
            return
        }

        let index = activeIndex

        pushUndo()
        history.remove(at: index)
        autoHistory = history

        let newIndex = index > 0 ? index - 1 : 0
        applyHistoryEntry(history[newIndex])
    }

    func deleteHistoryEntry(id: UUID) {
        var history = autoHistory

        if history.count <= 1 {
            clearHistory()
            return
        }

        guard let index = history.firstIndex(where: { $0.id == id }) else { return }

        let isActive = id == activeHistoryID

        pushUndo()
        history.remove(at: index)
        autoHistory = history

        if isActive {
            let newIndex = index > 0 ? index - 1 : 0
            applyHistoryEntry(history[newIndex])
        }
    }

    private var hasActiveSelection: Bool {
        guard let id = activeHistoryID else { return false }
        return activePairs.contains { $0.id == id }
    }

    func navigatePrevious() {
        let pairs = activePairs
        guard !pairs.isEmpty else { return }
        if !hasActiveSelection {
            applyEntry(pairs[pairs.count - 1])
            return
        }
        let nextIndex = activeIndex + 1
        guard nextIndex < pairs.count else { return }
        applyEntry(pairs[nextIndex])
    }

    func navigateNext() {
        let pairs = activePairs
        guard !pairs.isEmpty else { return }
        if !hasActiveSelection {
            applyEntry(pairs[0])
            return
        }
        let nextIndex = activeIndex - 1
        guard nextIndex >= 0 else { return }
        applyEntry(pairs[nextIndex])
    }

    func applyEntry(_ pair: ColorPair) {
        foreground.color = pair.foregroundColor
        background.color = pair.backgroundColor
        if Defaults[.activePaletteIndex] != 0 {
            recordHistory()
            lastAutoHistoryID = activeHistoryID
        }
        activeHistoryID = pair.id
    }

    func applyHistoryEntry(_ pair: ColorPair) {
        applyEntry(pair)
    }

    func restoreAutoHistorySelection() {
        if let id = lastAutoHistoryID,
           autoHistory.contains(where: { $0.id == id })
        {
            activeHistoryID = id
        } else if let first = autoHistory.first {
            activeHistoryID = first.id
        }
        lastAutoHistoryID = nil
    }

    // MARK: - Palette management

    func savePalette(name: String) {
        let current = ColorPair(
            id: UUID(),
            foregroundHex: foreground.color.toHexString(),
            backgroundHex: background.color.toHexString(),
            date: Date()
        )
        let palette = Palette(id: UUID(), name: name, pairs: [current], createdAt: Date())
        var palettes = Defaults[.palettes]
        palettes.append(palette)
        Defaults[.palettes] = palettes
        Defaults[.activePaletteIndex] = palettes.count - 1
        activeHistoryID = current.id
    }

    func renamePalette(at index: Int, to name: String) {
        var palettes = Defaults[.palettes]
        guard index > 0, index < palettes.count else { return }
        palettes[index].name = name
        Defaults[.palettes] = palettes
    }

    func deletePalette(at index: Int) {
        var palettes = Defaults[.palettes]
        guard index > 0, index < palettes.count else { return }
        palettes.remove(at: index)
        Defaults[.palettes] = palettes
        let currentIndex = Defaults[.activePaletteIndex]
        if currentIndex >= palettes.count {
            Defaults[.activePaletteIndex] = 0
            restoreAutoHistorySelection()
        } else if currentIndex > index {
            Defaults[.activePaletteIndex] = currentIndex - 1
        }
    }

    func addCurrentToPalette(at index: Int) {
        var palettes = Defaults[.palettes]
        guard index > 0, index < palettes.count else { return }
        let pair = ColorPair(
            id: UUID(),
            foregroundHex: foreground.color.toHexString(),
            backgroundHex: background.color.toHexString(),
            date: Date()
        )
        palettes[index].pairs.insert(pair, at: 0)
        Defaults[.palettes] = palettes
        activeHistoryID = pair.id
    }

    func deleteChipFromPalette(paletteIndex: Int, pairID: UUID) {
        var palettes = Defaults[.palettes]
        guard paletteIndex > 0, paletteIndex < palettes.count else { return }
        palettes[paletteIndex].pairs.removeAll { $0.id == pairID }
        Defaults[.palettes] = palettes
        if activeHistoryID == pairID { activeHistoryID = nil }
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
            NotificationCenter.default.post(name: .systemColorChanged, object: nil)
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
