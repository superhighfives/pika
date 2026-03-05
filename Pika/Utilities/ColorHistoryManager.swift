import Cocoa
import Defaults

/// Manages a most-recently-used list of picked colors, persisted via Defaults.
/// Two recording modes: immediate (eyedropper picks) and debounced (system color panel,
/// which fires continuously as the user drags).
class ColorHistoryManager {
    static let maxEntries = 20
    private var debounceWorkItem: DispatchWorkItem?

    func recordImmediate(_ color: NSColor) {
        addColor(color)
    }

    /// Coalesces rapid-fire color changes (e.g. dragging in NSColorPanel) into a single history entry.
    func recordDebounced(_ color: NSColor) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.addColor(color)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    /// Promotes an existing color to the front of the list, or inserts it if new.
    /// Called directly by views when tapping a history swatch (without re-recording).
    func moveToFront(hex: String) {
        var history = Defaults[.colorHistory]
        if let index = history.firstIndex(of: hex) {
            history.remove(at: index)
        }
        history.insert(hex, at: 0)
        if history.count > Self.maxEntries {
            history = Array(history.prefix(Self.maxEntries))
        }
        Defaults[.colorHistory] = history
    }

    private func addColor(_ color: NSColor) {
        moveToFront(hex: color.toHexString())
    }
}
