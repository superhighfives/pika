import AppKit

/// Abstracts the "pick a colour for this target" step so the eyedropper commit
/// path (set / history / undo / overlay / chaining) can stay identical across the
/// system sampler and the custom loupe. Only the picking UI differs — the caller
/// handles everything after a colour comes back.
///
/// See `plans/ready/2026-07-19-custom-color-picker.md`.
protocol ColorPickSession: AnyObject {
    /// Begins a single pick for `target`. Calls `completion` with the chosen
    /// `NSColor`, or `nil` if the pick was cancelled.
    ///
    /// - Parameters:
    ///   - target: which slot is being picked (drives the loupe's slot indicator).
    ///   - comparison: the already-picked colour in the *other* slot, used by the
    ///     custom loupe for live contrast. The system sampler ignores it.
    ///   - willChain: `true` when a successful pick will immediately hand off to a
    ///     second (background) pick — the custom loupe uses this to stay visible
    ///     across the pair instead of tearing down between picks. Ignored by the
    ///     system sampler.
    ///   - completion: called once with the picked colour or `nil`.
    func begin(
        target: Eyedropper.Types,
        comparison: NSColor?,
        willChain: Bool,
        completion: @escaping (NSColor?) -> Void
    )

    /// Cancels an in-flight pick and tears down any picking UI.
    func cancel()
}

/// Wraps `NSColorSampler` — the default picker and the guaranteed fallback. With
/// `Defaults[.pickerStyle] == .system` this is byte-for-byte today's behaviour.
final class SystemColorPickSession: ColorPickSession {
    private let sampler = NSColorSampler()

    func begin(
        target _: Eyedropper.Types,
        comparison _: NSColor?,
        willChain _: Bool,
        completion: @escaping (NSColor?) -> Void
    ) {
        sampler.show { completion($0) }
    }

    func cancel() {
        // NSColorSampler owns its own lifecycle and exposes no cancel API.
    }
}
