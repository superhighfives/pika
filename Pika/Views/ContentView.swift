import Combine
import Defaults
import SwiftUI
import UniformTypeIdentifiers

/// Height thresholds (in points of available window content height) below which each
/// element is shed, so the window can shrink far smaller than the sum of everything.
/// Ordered largest-first to match the shed order: palettes drop first, then contrast,
/// preview, and colour names. Type labels never shed on height — the window floor (160)
/// sits above any useful threshold for them. These are the tuning knobs for the adaptive
/// layout.
enum PikaAdaptiveHeight {
    static let floor: CGFloat = 160 // bare minimum content height (matches window frame min ≈ 200pt window)
    static let expandCornerBelow: CGFloat = 200 // below this content height (~240pt window) the button tucks top-right
    static let palettes: CGFloat = 300 // history drawer (`ColorHistoryDrawer.height`, 74pt)
    static let contrast: CGFloat = 250 // compliance footer (~50pt)
    static let preview: CGFloat = 200 // the preview's "Aa"
    static let previewSentence: CGFloat = 290 // the preview's sample sentence, under the "Aa"
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
    static let preview: CGFloat = 460 // the preview's sentence (each colour 230 wide)
}

/// Size-driven visibility for elements inside the eyedropper rows, threaded down to
/// the deeply-nested `EyedropperButton` via the environment. `true` means "there is
/// room" — it's ANDed with the user's own preference at the point of use, so a saved
/// setting is never mutated (suppress-but-remember).
struct PikaAdaptiveVisibility: Equatable {
    var showsTypeLabels: Bool = true
    var showsColorNames: Bool = true
    /// Width of a single swatch (half the window's content width — the two panels split it
    /// evenly with no gap). Read from this outer `GeometryReader`, not measured again lower in
    /// the tree: a `GeometryReader`/preference round trip placed inside `EyedropperButton`'s own
    /// `ZStack` was found to never fire past its initial (zero) value.
    var swatchWidth: CGFloat = 0
    /// Space kept clear at the bottom of each swatch for the floating contrast bar, so the
    /// readouts sit above it. 0 when the bar is hidden.
    var bottomInset: CGFloat = 0
    /// Whether each swatch shows the text preview: the other colour set as "Aa" and a line of
    /// sample text, so the pair reads both ways round.
    var showsPreview: Bool = false
    /// Whether the preview has room for its sample sentence; without it, it's just "Aa".
    var showsPreviewSentence: Bool = true
}

private struct PikaAdaptiveVisibilityKey: EnvironmentKey {
    static let defaultValue = PikaAdaptiveVisibility()
}

extension EnvironmentValues {
    var pikaAdaptiveVisibility: PikaAdaptiveVisibility {
        get { self[PikaAdaptiveVisibilityKey.self] }
        set { self[PikaAdaptiveVisibilityKey.self] = newValue }
    }

    /// Whether palettes show as a sidebar (the main window) rather than a drawer along the
    /// bottom (the menu bar popover, which has no room for one).
    var pikaUsesSidebar: Bool {
        get { self[PikaUsesSidebarKey.self] }
        set { self[PikaUsesSidebarKey.self] = newValue }
    }
}

private struct PikaUsesSidebarKey: EnvironmentKey {
    static let defaultValue = false
}

struct ContentView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers

    @Default(.copyFormat) var copyFormat
    @Default(.colorFormat) var colorFormat
    @Default(.historyDrawerVisible) var historyDrawerVisible
    @Default(.showColorPreview) var showColorPreview
    @Default(.showCompliance) var showCompliance
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.pikaUsesSidebar) var usesSidebar
    @ObservedObject private var sidebarLayout = SidebarLayout.shared
    let pasteboard = NSPasteboard.general

    @State var swapVisible: Bool = false
    @State private var swapTimerSubscription: Cancellable?
    @State private var swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)
    @State private var swapAreaHovered = false
    @State private var swapButtonHovered = false
    @State private var isHovering: Bool = false
    #if TARGET_SPARKLE
        /// Observed here, not just in the bar, so the swatches resize with the update bar as it
        /// slides in and out.
        @ObservedObject private var updates = PikaUpdateDriver.shared
    #endif

    /// The "expand to fit" target: the largest width and height each enabled element needs,
    /// plus a small margin so it lands just past each threshold.
    private func expandTargetSize() -> CGSize {
        let margin: CGFloat = 8
        var width = PikaAdaptiveWidth.base
        var height = PikaAdaptiveHeight.floor
        // The whole preview, sentence and all: "Aa" alone fits at any width.
        if showColorPreview {
            width = max(width, PikaAdaptiveWidth.preview)
            height = max(height, PikaAdaptiveHeight.previewSentence)
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

    /// Shows Swap while a pick area or the button itself is hovered, and hides it a quarter
    /// second after neither is, so moving between the two swatches or onto the button keeps it.
    private func updateSwapVisibility() {
        if swapAreaHovered || swapButtonHovered {
            swapVisible = true
            swapTimerSubscription?.cancel()
            swapTimerSubscription = nil
        } else if swapTimerSubscription == nil {
            swapTimer = Timer.publish(every: 0.25, on: .main, in: .common)
            swapTimerSubscription = swapTimer.connect()
        }
    }

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            // The palettes sidebar takes its column off the left; everything else lays out in
            // what's left, so the colours and their thresholds see the main area only.
            let sidebarColumn = usesSidebar ? sidebarLayout.column(in: geo.size.width) : 0
            let sidebarShown = sidebarColumn > 0
            let width = geo.size.width - sidebarColumn
            // Room-for flags: an element needs both enough height AND enough width, or it
            // clips. ANDed with user preferences below so the saved toggles survive
            // resizing (suppress-but-remember).
            // "Aa" alone fits at any width; the sentence needs more (`showsPreviewSentence`).
            let allowPreview = height >= PikaAdaptiveHeight.preview
            // The contrast footer clings on far longer than the other elements. On height it
            // stays until the window is short enough that the expand affordance tucks into
            // the corner; on width it never hides outright — instead the WCAG/APCA rows drop
            // just their right-hand compliance badges, keeping the left-most ratio value.
            let allowContrastHeight = height >= PikaAdaptiveHeight.expandCornerBelow
            let allowContrastWidth = width >= PikaAdaptiveWidth.contrast
            let allowContrast = allowContrastHeight && allowContrastWidth
            let allowPalettes = usesSidebar
                ? sidebarShown
                : height >= PikaAdaptiveHeight.palettes && width >= PikaAdaptiveWidth.palettes
            let previewVisible = showColorPreview && allowPreview
            let contrastVisible = showCompliance && allowContrastHeight

            // An enabled element we're hiding purely for space. When any exist, offer to
            // grow the window back to a size that fits everything the user has turned on.
            let suppressed = (showColorPreview && !allowPreview)
                || (showCompliance && !allowContrast)
                || (historyDrawerVisible && !allowPalettes && sidebarLayout.heldColourWidth == nil) // not mid-resize
            // Always tuck the expand affordance into the top-right corner so it never sits
            // on top of the colour values.
            let expandAlignment: Alignment = .topTrailing

            // One divider under the title bar, across the sidebar and the colours.
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 0) {
                    // Revealed by its column as the window widens; kept at zero width, not removed.
                    if usesSidebar {
                        HStack(spacing: 0) {
                            PaletteSidebar()
                            AdaptiveDivider(axis: .vertical)
                        }
                        .frame(width: sidebarColumn, alignment: .trailing)
                        .clipped()
                        .allowsHitTesting(sidebarShown).accessibilityHidden(!sidebarShown)
                    }
                    VStack(alignment: .trailing, spacing: 0) {
                        // Swap shows while the colours (or Swap itself) are hovered.
                        ColorPickers(onHover: { hovered in
                            swapAreaHovered = hovered
                            updateSwapVisibility()
                        })
                        .onReceive(swapTimer) { _ in
                            if !swapAreaHovered, !swapButtonHovered { swapVisible = false }
                            swapTimerSubscription?.cancel()
                            swapTimerSubscription = nil
                        }
                        .overlay(
                            SwapPreviewButton(
                                foreground: eyedroppers.foreground,
                                background: eyedroppers.background,
                                showPreview: false,
                                isVisible: swapVisible,
                                onHoverChange: { hovered in
                                    swapButtonHovered = hovered
                                    updateSwapVisibility()
                                },
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
                            // Bottom right, above the contrast bar and clear of the previews and values.
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, Footer.floatingInset)
                            .padding(.bottom, (contrastVisible ? Footer.floatingHeight + Footer.floatingInset : 0) + Footer.floatingInset)
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

                        // The contrast bar floats over the bottom of the colours rather than sitting
                        // in a band under them. The swatches keep `bottomInset` clear for it.
                        .overlay(alignment: .bottom) {
                            if contrastVisible {
                                // `showsCompliance` drops the right-hand badges when there isn't the
                                // width for them, so the bar stays put and only sheds on height.
                                Footer(
                                    foreground: eyedroppers.foreground,
                                    background: eyedroppers.background,
                                    showsCompliance: allowContrastWidth,
                                    floating: true
                                )
                                .padding(Footer.floatingInset)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        if historyDrawerVisible, allowPalettes, !usesSidebar {
                            ColorHistoryDrawer(foreground: eyedroppers.foreground, background: eyedroppers.background)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        #if TARGET_SPARKLE
                            InlineUpdateControl()
                        #endif
                    }
                    .frame(width: width, alignment: .top)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .environment(\.pikaAdaptiveVisibility, PikaAdaptiveVisibility(
                // Previews sit at the top and labels at the bottom, so the labels never shed for them.
                showsTypeLabels: true,
                showsColorNames: height >= PikaAdaptiveHeight.colorNames,
                swatchWidth: width / 2,
                bottomInset: contrastVisible ? Footer.floatingHeight + Footer.floatingInset : 0,
                showsPreview: previewVisible,
                showsPreviewSentence: width >= PikaAdaptiveWidth.preview && height >= PikaAdaptiveHeight.previewSentence
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
            .animation(.easeInOut(duration: 0.2), value: contrastVisible)
            .animation(.easeInOut(duration: 0.2), value: allowContrastHeight)
            .animation(.easeInOut(duration: 0.2), value: allowContrastWidth)
            .animation(.easeInOut(duration: 0.2), value: !usesSidebar && allowPalettes) // the drawer's
            .animation(.easeInOut(duration: 0.15), value: suppressed)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            #if TARGET_SPARKLE
                .animation(.easeInOut(duration: 0.25), value: updates.state == .idle)
            #endif
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
        .onReceive(NotificationCenter.default.publisher(for: .exportPalette)) { exportPalette($0) }
    }
}

extension ContentView {
    /// Saves a palette (the one in the notification, else the active one) as JSON.
    func exportPalette(_ notification: Notification) {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Eyedroppers())
    }
}
