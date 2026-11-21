import Defaults
import SwiftUI

/// The main window's palettes, as a library down the left: the palettes listed with their counts,
/// then the selected one's pairs as small "Aa" tiles in the pair's own colours, each with its
/// contrast ratio. The menu bar popover keeps the drawer instead (`ColorHistoryDrawer`).
/// Whether the main window's sidebar shows, and how wide its column is while the window resizes
/// for it. `WindowCoordinator` drives this rather than the layout reading `historyDrawerVisible`
/// directly: it notes the colours' width, then animates the window, and the column is whatever
/// the window has added. The colours keep their width the whole way, where reading the setting
/// straight away squeezed them to make room before the window had grown.
final class SidebarLayout: ObservableObject {
    static let shared = SidebarLayout()

    /// The sidebar and the divider beside it.
    static let fullWidth = PaletteSidebar.width + AdaptiveDivider.thickness

    @Published var isVisible = Defaults[.historyDrawerVisible]
    /// The colours' width, held while the window resizes for the sidebar. `nil` otherwise.
    @Published var heldColourWidth: CGFloat?
    /// Set just before a toggle from the View menu, at the window's top right, so the window
    /// grows and shrinks on its left and the menu stays under the pointer. The title bar's
    /// sidebar button, at the top left, leaves it unset and the window changes on its right.
    var keepsRightEdge = false
    /// Set while the window grows or shrinks on its left. The layout pins the colours to the
    /// right edge, so the frame its geometry lags behind the window shows at the sidebar's edge
    /// rather than as a gap of window background beside the colours.
    @Published var pinsRight = false

    /// The sidebar's column in a window `width` wide.
    func column(in width: CGFloat) -> CGFloat {
        if let held = heldColourWidth {
            return min(max(width - held, 0), Self.fullWidth)
        }
        return isVisible && width >= PikaAdaptiveWidth.base + Self.fullWidth ? Self.fullWidth : 0
    }
}

struct PaletteSidebar: View {
    static let width: CGFloat = 200

    @EnvironmentObject var eyedroppers: Eyedroppers
    @Default(.palettes) var palettes
    @Default(.activePaletteIndex) var activePaletteIndex
    @Default(.historyDrawerVisible) var historyDrawerVisible

    @State private var isShowingNewField = false
    @State private var renamingIndex: Int?
    @State private var isShowingClearConfirm = false

    private var activePalette: Palette? {
        guard activePaletteIndex >= 0, activePaletteIndex < palettes.count else { return palettes.first }
        return palettes[activePaletteIndex]
    }

    private var isAutoHistory: Bool { activePalette?.isAutoHistory ?? true }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(PikaText.textViewPalettes)
            VStack(spacing: 1) {
                ForEach(Array(palettes.enumerated()), id: \.element.id) { index, palette in
                    if renamingIndex == index {
                        PaletteNameField(
                            placeholder: palette.name ?? PikaText.textPaletteNamePlaceholder,
                            onSubmit: { name in
                                eyedroppers.renamePalette(at: index, to: name)
                                renamingIndex = nil
                            },
                            onCancel: { renamingIndex = nil }
                        )
                    } else {
                        paletteRow(palette, index: index)
                    }
                }
                if isShowingNewField {
                    PaletteNameField(
                        placeholder: PikaText.textPaletteNamePlaceholder,
                        onSubmit: { name in
                            withAnimation(.easeInOut(duration: 0.2)) { eyedroppers.savePalette(name: name) }
                            isShowingNewField = false
                        },
                        onCancel: { isShowingNewField = false }
                    )
                } else {
                    Button(action: { isShowingNewField = true }) {
                        Label(PikaText.textPaletteNew, systemImage: "plus")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)

            Divider().padding(.horizontal, 10).padding(.vertical, 8)

            HStack {
                sectionHeader(activePalette.map(title(of:)) ?? "")
                Spacer()
                paletteAction
            }
            .padding(.trailing, 12)

            GeometryReader { geo in
                let tileHeight = Self.tileHeight(showingHalfRowIn: geo.size.height)
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: Self.rowSpacing) {
                        ForEach(activePalette?.pairs ?? []) { pair in
                            SidebarSwatch(
                                pair: pair,
                                tileHeight: tileHeight,
                                isActive: pair.id == eyedroppers.activeHistoryID,
                                isAutoHistory: isAutoHistory,
                                onApplyBoth: { eyedroppers.applyHistoryEntry(pair) },
                                onApplyForeground: {
                                    eyedroppers.foreground.set(pair.foregroundColor)
                                    eyedroppers.recordHistory()
                                },
                                onApplyBackground: {
                                    eyedroppers.background.set(pair.backgroundColor)
                                    eyedroppers.recordHistory()
                                },
                                onRemove: { remove(pair) },
                                onClearAll: isAutoHistory ? { isShowingClearConfirm = true } : nil
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    // Room for the selected swatch's ring, which sits outside the tile.
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                    .animation(.easeInOut(duration: 0.2), value: activePalette?.pairs)
                }
            }
        }
        .padding(.top, 8)
        .frame(width: Self.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AdaptivePanelBackground())
        .onReceive(NotificationCenter.default.publisher(for: .savePalette)) { _ in
            if !historyDrawerVisible {
                withAnimation(.easeInOut(duration: 0.25)) { historyDrawerVisible = true }
            }
            isShowingNewField = true
        }
        .alert(PikaText.textHistoryClear, isPresented: $isShowingClearConfirm) {
            Button(PikaText.textClear, role: .destructive) { eyedroppers.clearHistory() }
            Button(PikaText.textCancel, role: .cancel) {}
        } message: {
            Text(PikaText.textHistoryClearConfirm)
        }
    }

    private static let rowSpacing: CGFloat = 6
    /// A swatch's row, less the tile: the gap above the ratio, the ratio and the row spacing.
    private static let rowExtras: CGFloat = 3 + 13 + rowSpacing

    /// Tile height that leaves half a row showing at the bottom of `height`, so it's clear the
    /// grid scrolls. Picks the whole number of rows nearest the default tile size, then sizes
    /// the tiles to fit that many and a half.
    static func tileHeight(showingHalfRowIn height: CGFloat) -> CGFloat {
        let preferred: CGFloat = 34
        let available = height - 4
        guard available > 0 else { return preferred }
        let rows = max(1, ((available / (preferred + rowExtras)) - 0.5).rounded())
        return min(max(available / (rows + 0.5) - rowExtras, 28), 44)
    }

    private func title(of palette: Palette) -> String {
        palette.isAutoHistory ? PikaText.textHistoryTitle : (palette.name ?? "")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
    }

    /// Clear for the history, add the current pair for a named palette.
    @ViewBuilder private var paletteAction: some View {
        if isAutoHistory {
            Button(action: { isShowingClearConfirm = true }) {
                Image(systemName: "trash").font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(PikaText.textHistoryClear)
            .padding(.bottom, 6)
        } else {
            Button(action: { eyedroppers.addCurrentToPalette(at: activePaletteIndex) }) {
                Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(PikaText.textPaletteAddColor)
            .padding(.bottom, 6)
        }
    }

    private func paletteRow(_ palette: Palette, index: Int) -> some View {
        let isSelected = index == activePaletteIndex
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { activePaletteIndex = index }
            if index == 0 { eyedroppers.restoreAutoHistorySelection() }
        }) {
            HStack(spacing: 8) {
                paletteIcon(palette)
                Text(title(of: palette))
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("\(palette.pairs.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.1) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if palette.isAutoHistory {
                Button(PikaText.textHistoryExport) {
                    NotificationCenter.default.post(name: .exportPalette, object: index)
                }
                Button(PikaText.textHistoryClear) { isShowingClearConfirm = true }
            } else {
                Button(PikaText.textPaletteRename) { renamingIndex = index }
                Button(PikaText.textPaletteExport) {
                    NotificationCenter.default.post(name: .exportPalette, object: index)
                }
                Divider()
                Button(PikaText.textPaletteDelete) { eyedroppers.deletePalette(at: index) }
            }
        }
    }

    /// The history's clock, or a named palette's first pair split on the diagonal.
    @ViewBuilder private func paletteIcon(_ palette: Palette) -> some View {
        if palette.isAutoHistory {
            Image(systemName: "clock").font(.system(size: 12)).frame(width: 14)
        } else if let first = palette.pairs.first {
            ZStack {
                Color(first.backgroundColor)
                Color(first.foregroundColor).clipShape(DiagonalHalf())
            }
            .frame(width: 14, height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 3.5, style: .continuous).strokeBorder(Color.primary.opacity(0.15)))
        } else {
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.6))
                .frame(width: 14, height: 14)
        }
    }

    private func remove(_ pair: ColorPair) {
        if isAutoHistory {
            eyedroppers.deleteHistoryEntry(id: pair.id)
        } else {
            eyedroppers.deleteChipFromPalette(paletteIndex: activePaletteIndex, pairID: pair.id)
        }
    }
}

/// The top-left triangle of a square, for a palette's two-colour icon.
private struct DiagonalHalf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

/// One saved pair: "Aa" in the foreground on the background, with its WCAG ratio underneath,
/// bold when it passes AA for normal text.
private struct SidebarSwatch: View {
    let pair: ColorPair
    var tileHeight: CGFloat = 34
    let isActive: Bool
    let isAutoHistory: Bool
    let onApplyBoth: () -> Void
    let onApplyForeground: () -> Void
    let onApplyBackground: () -> Void
    let onRemove: () -> Void
    let onClearAll: (() -> Void)?

    @State private var isHovered = false

    private var ratio: CGFloat { pair.foregroundColor.contrastRatio(with: pair.backgroundColor) }

    var body: some View {
        VStack(spacing: 3) {
            Text("Aa")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(pair.foregroundColor))
                .frame(maxWidth: .infinity)
                .frame(height: tileHeight)
                .background(Color(pair.backgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .padding(-3)
                        .opacity(isActive ? 1 : 0)
                )
                .shadow(color: .black.opacity(isHovered ? 0.25 : 0), radius: 3, y: 1)
            Text(String(format: "%.1f", ratio))
                .font(.system(size: 10, weight: ratio >= 4.5 ? .semibold : .regular))
                .foregroundStyle(ratio >= 4.5 ? Color.primary.opacity(0.85) : Color.secondary)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onApplyBoth)
        .contextMenu {
            Button(PikaText.textHistoryApplyForeground, action: onApplyForeground)
            Button(PikaText.textHistoryApplyBackground, action: onApplyBackground)
            Divider()
            Button(isAutoHistory ? PikaText.textHistoryRemove : PikaText.textPaletteRemoveChip, action: onRemove)
            if let onClearAll {
                Button(PikaText.textHistoryClear, action: onClearAll)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// The title bar's sidebar button, beside the traffic lights, as in Finder and Mail. It flips the
/// same setting as View → Palettes, so the two can't disagree. Main window only: the popover has
/// no sidebar, and its View menu still shows and hides the palette drawer.
struct SidebarToggleButton: View {
    @Default(.historyDrawerVisible) var historyDrawerVisible

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { historyDrawerVisible.toggle() }
        } label: {
            IconImage(name: "sidebar.left")
                .foregroundStyle(historyDrawerVisible ? Color.primary : Color.secondary)
                .frame(width: 28, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .padding(.leading, 6.0)
        .help(PikaText.textViewPalettes)
        .accessibilityLabel(PikaText.textViewPalettes)
        .accessibilityAddTraits(historyDrawerVisible ? .isSelected : [])
    }
}
