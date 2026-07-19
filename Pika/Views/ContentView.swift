import Combine
import Defaults
import SwiftUI
import UniformTypeIdentifiers

/// Height thresholds (in points of available window content height) below which each
/// element is shed, so the window can shrink far smaller than the sum of everything.
/// Ordered largest-first to match the shed order: palettes drop first, then contrast,
/// preview, and colour names. Type labels are the last to go, but they hide only via the
/// preview-pill overlap — the window floor (160) sits above any useful height threshold
/// for them. These are the tuning knobs for the adaptive layout.
enum PikaAdaptiveHeight {
    static let floor: CGFloat = 160 // bare minimum content height (matches window frame min ≈ 200pt window)
    static let expandCornerBelow: CGFloat = 200 // below this content height (~240pt window) the button tucks top-right
    static let palettes: CGFloat = 300 // history drawer (~74pt)
    static let contrast: CGFloat = 250 // compliance footer (~50pt)
    static let preview: CGFloat = 200 // preview pill
    static let colorNames: CGFloat = 175 // CSS colour name under each value
}

/// Width thresholds below which horizontally-laid-out elements are shed rather than left
/// to clip past the window edge. The footer's contrast panels are the widest content.
enum PikaAdaptiveWidth {
    static let base: CGFloat = 360 // bare minimum content width (matches window frame min)
    // Footer (with its shortened labels) and the palette drawer share one hide width so
    // they appear/disappear together — different values read as a bug.
    static let palettes: CGFloat = 410
    static let contrast: CGFloat = 410
    static let preview: CGFloat = 420 // preview pill
}

/// Size-driven visibility for elements inside the eyedropper rows, threaded down to
/// the deeply-nested `EyedropperButton` via the environment. `true` means "there is
/// room" — it's ANDed with the user's own preference at the point of use, so a saved
/// setting is never mutated (suppress-but-remember).
struct PikaAdaptiveVisibility: Equatable {
    var showsTypeLabels: Bool = true
    var showsColorNames: Bool = true
}

private struct PikaAdaptiveVisibilityKey: EnvironmentKey {
    static let defaultValue = PikaAdaptiveVisibility()
}

extension EnvironmentValues {
    var pikaAdaptiveVisibility: PikaAdaptiveVisibility {
        get { self[PikaAdaptiveVisibilityKey.self] }
        set { self[PikaAdaptiveVisibilityKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Default(.showColorPreview) var showColorPreview
    @Default(.showCompliance) var showCompliance
    @Default(.appMode) var appMode
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let pasteboard = NSPasteboard.general

    @State var swapVisible: Bool = false
    @State private var swapTimerSubscription: Cancellable?
    @State private var swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var isHovering: Bool = false

    /// Content size that comfortably shows every element the user currently has enabled —
    /// the target for the "expand to fit" control. Takes the largest width/height each
    /// enabled element needs, plus a small margin so it lands just past each threshold.
    private func expandTargetSize() -> CGSize {
        let margin: CGFloat = 8
        var width = PikaAdaptiveWidth.base
        var height = PikaAdaptiveHeight.floor
        if showColorPreview {
            width = max(width, PikaAdaptiveWidth.preview)
            height = max(height, PikaAdaptiveHeight.preview)
        }
        if showCompliance {
            width = max(width, PikaAdaptiveWidth.contrast)
            height = max(height, PikaAdaptiveHeight.contrast)
        }
        if historyDrawerVisible {
            width = max(width, PikaAdaptiveWidth.palettes)
            height = max(height, PikaAdaptiveHeight.palettes)
        }
        return CGSize(width: width + margin, height: height + margin)
    }

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            // Room-for flags: an element needs both enough height AND enough width, or it
            // clips. ANDed with user preferences below so the saved toggles survive
            // resizing (suppress-but-remember).
            let allowPreview = height >= PikaAdaptiveHeight.preview && width >= PikaAdaptiveWidth.preview
            let allowContrast = height >= PikaAdaptiveHeight.contrast && width >= PikaAdaptiveWidth.contrast
            let allowPalettes = height >= PikaAdaptiveHeight.palettes && width >= PikaAdaptiveWidth.palettes
            // The preview pill overlaps the type labels, so labels only show when the
            // pill is effectively hidden.
            let previewVisible = showColorPreview && allowPreview

            // An enabled element we're hiding purely for space. When any exist, offer to
            // grow the window back to a size that fits everything the user has turned on.
            let suppressed = (showColorPreview && !allowPreview)
                || (showCompliance && !allowContrast)
                || (historyDrawerVisible && !allowPalettes)
            // Centre the affordance normally, but at very short heights tuck it into the
            // top-right corner so it doesn't sit on top of the colour values.
            let expandAlignment: Alignment = height < PikaAdaptiveHeight.expandCornerBelow ? .topTrailing : .center

            VStack(alignment: .trailing, spacing: 0) {
                Divider()
                ColorPickers()
                    .onHover { hover in
                        guard hover else { return }
                        swapVisible = true
                        swapTimerSubscription?.cancel()
                        swapTimerSubscription = nil
                    }
                    .onReceive(swapTimer) { _ in
                        swapVisible = false
                        swapTimerSubscription?.cancel()
                        swapTimerSubscription = nil
                    }
                    .overlay(
                        SwapPreviewButton(
                            foreground: eyedroppers.foreground,
                            background: eyedroppers.background,
                            showPreview: previewVisible,
                            isVisible: swapVisible,
                            onSwap: {
                                NSApp.sendAction(#selector(AppDelegate.triggerSwap), to: nil, from: nil)
                            }
                        )
                        .onReceive(NotificationCenter.default.publisher(for: .triggerSwap)) { _ in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                eyedroppers.swap()
                            }
                        }
                        .focusable(false)
                        .padding(.horizontal, 16.0)
                        .padding(.top, appMode.usesPopover ? 42.0 : 16.0)
                        .frame(maxHeight: .infinity, alignment: .top)
                    )
                    // Expand-to-fit sits over the colour tiles (not the whole app), so it
                    // centres on the swatches rather than drifting down over the footer.
                    .overlay(alignment: expandAlignment) {
                        if suppressed, isHovering {
                            ExpandToFitButton {
                                NotificationCenter.default.post(
                                    name: .expandToFit,
                                    object: NSValue(size: expandTargetSize())
                                )
                            }
                            .padding(expandAlignment == .topTrailing ? 8 : 0)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }
                    }
                    .onHover { hover in
                        guard !hover, swapTimerSubscription == nil else {
                            return
                        }
                        swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)
                        swapTimerSubscription = swapTimer.connect()
                    }

                if showCompliance, allowContrast {
                    AdaptiveDivider()
                    // Slide only — no opacity fade, so the footer is always full opacity.
                    Footer(foreground: eyedroppers.foreground, background: eyedroppers.background)
                        .transition(.move(edge: .bottom))
                }
                if historyDrawerVisible, allowPalettes {
                    ColorHistoryDrawer(foreground: eyedroppers.foreground, background: eyedroppers.background)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .environment(\.pikaAdaptiveVisibility, PikaAdaptiveVisibility(
                // Type labels sit behind the preview pill, so they hide only when it shows
                // — the window floor keeps height above any threshold that would drop them.
                showsTypeLabels: !previewVisible,
                showsColorNames: height >= PikaAdaptiveHeight.colorNames
            ))
            // Continuous hover is stable when the button appears under the cursor —
            // plain `.onHover` re-fires enter/exit as the overlay mounts, which flickers
            // the button (and re-wraps the value text) in a loop.
            .onContinuousHover { phase in
                switch phase {
                case .active: isHovering = true
                case .ended: isHovering = false
                }
            }
            .animation(.easeInOut(duration: 0.2), value: allowContrast)
            .animation(.easeInOut(duration: 0.2), value: allowPalettes)
            .animation(.easeInOut(duration: 0.15), value: suppressed)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .onAppear {
            if Defaults[.palettes].first?.pairs.isEmpty ?? true {
                eyedroppers.recordHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorPicked)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                eyedroppers.recordHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .systemColorChanged)) { _ in
            eyedroppers.updateActiveEntry()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleHistory)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                historyDrawerVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleColorPreview)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showColorPreview.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleCompliance)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                showCompliance.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyPrevious)) { _ in
            guard historyDrawerVisible else { return }
            eyedroppers.navigatePrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyNext)) { _ in
            guard historyDrawerVisible else { return }
            eyedroppers.navigateNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyDelete)) { _ in
            guard historyDrawerVisible else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                eyedroppers.deleteCurrentEntry()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyText)) { _ in
            pasteboard.clearContents()
            let contents = Exporter.toText(
                foreground: eyedroppers.foreground, background: eyedroppers.background,
                style: copyFormat
            )
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCopyData)) { _ in
            pasteboard.clearContents()
            let contents = Exporter.toJSON(
                foreground: eyedroppers.foreground, background: eyedroppers.background,
                style: copyFormat
            )
            pasteboard.setString(contents, forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPalette)) { notification in
            let idx: Int
            if let paletteIndex = notification.object as? Int {
                idx = paletteIndex
            } else if !historyDrawerVisible {
                idx = 0
            } else {
                idx = activePaletteIndex
            }
            let palette: Palette? = (idx >= 0 && idx < palettes.count) ? palettes[idx] : palettes.first
            guard let palette = palette else { return }

            let json = Exporter.paletteToJSON(pairs: palette.pairs, name: palette.name)
            let invalidChars = CharacterSet(charactersIn: "/:\\")
            let fileName = (palette.name ?? "color-history")
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .components(separatedBy: invalidChars)
                .joined()

            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(fileName).json"
            savePanel.isExtensionHidden = false
            if savePanel.runModal() == .OK, let url = savePanel.url {
                do {
                    try json.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
        }
    }
}

/// Shared surface for the footer and palette drawer. In light mode the under-window
/// vibrancy material washes out to near-nothing, so use the standard window background
/// for a clearly-defined panel; dark mode keeps the material, which reads well there.
struct AdaptivePanelBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            VisualEffect(
                material: NSVisualEffectView.Material.underWindowBackground,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            )
        } else {
            Color(NSColor.windowBackgroundColor)
        }
    }
}

/// Divider that reads as a recessed seam in both appearances. The system `Divider`
/// renders too light over the footer/drawer materials in light mode (looks white rather
/// than a darker separator), so tint explicitly with `primary`, which flips per scheme.
struct AdaptiveDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    var axis: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.24))
            .frame(
                width: axis == .vertical ? 1 : nil,
                height: axis == .horizontal ? 1 : nil
            )
    }
}

/// Small floating capsule shown when the adaptive layout is hiding enabled elements.
/// Tapping it grows the window just enough to reveal them again.
private struct ExpandToFitButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5.0) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .semibold))
                Text(PikaText.textExpandToFit)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10.0)
            .padding(.vertical, 5.0)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12)))
            .opacity(hovering ? 1.0 : 0.9)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovering = $0 }
        .help(PikaText.textExpandToFit)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Eyedroppers())
    }
}
