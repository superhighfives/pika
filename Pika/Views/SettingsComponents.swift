import AppKit
import SwiftUI

// MARK: - Tabs

/// Settings' tabs, in toolbar order.
enum SettingsTab: String, CaseIterable {
    case general, appearance, picking, color, shortcuts

    var title: String {
        switch self {
        case .general: return PikaText.textSettingsGeneral
        case .appearance: return PikaText.textAppearanceTitle
        case .picking: return PikaText.textSettingsPicking
        case .color: return PikaText.textSettingsColor
        case .shortcuts: return PikaText.textSettingsShortcuts
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "macwindow"
        case .picking: return "eyedropper"
        case .color: return "paintpalette"
        case .shortcuts: return "command"
        }
    }

    @MainActor var page: AnyView {
        switch self {
        case .general: return AnyView(GeneralSettings())
        case .appearance: return AnyView(AppearanceSettings())
        case .picking: return AnyView(PickingSettings())
        case .color: return AnyView(ColorSettings())
        case .shortcuts: return AnyView(ShortcutSettings())
        }
    }
}

/// The Settings window's content: a standard macOS toolbar of tabs, the window titled after the
/// selected one and sized to fit it. Each tab is a SwiftUI page that reports its own size, so the
/// window also follows a tab that grows or shrinks, as when the Pro picker shows its loupe style.
final class SettingsTabController: NSTabViewController {
    init(eyedroppers: Eyedroppers) {
        super.init(nibName: nil, bundle: nil)
        tabStyle = .toolbar
        for tab in SettingsTab.allCases {
            let page = NSHostingController(rootView: tab.page.environmentObject(eyedroppers))
            page.sizingOptions = [.preferredContentSize]
            page.title = tab.title
            let item = NSTabViewItem(viewController: page)
            item.label = tab.title
            item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title)
            item.identifier = tab.rawValue
            addTabViewItem(item)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        view.window?.title = tabViewItem?.label ?? ""
        fitWindow(animate: true)
    }

    override func preferredContentSizeDidChange(for viewController: NSViewController) {
        super.preferredContentSizeDidChange(for: viewController)
        guard viewController == tabViewItems[selectedTabViewItemIndex].viewController else { return }
        fitWindow(animate: true)
    }

    /// Resizes the window to the selected tab, keeping its top edge where it is.
    func fitWindow(animate: Bool) {
        guard let window = view.window,
              let page = tabViewItems[selectedTabViewItemIndex].viewController
        else { return }
        let size = page.preferredContentSize
        guard size.height > 0 else { return }
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        guard frame != window.frame else { return }
        window.setFrame(frame, display: true, animate: animate && window.isVisible)
    }
}

// MARK: - Building blocks

/// One tab's content: grouped sections down a fixed-width column.
struct SettingsPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18.0) {
            content
        }
        .padding(20.0)
        .frame(width: 560.0, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A rounded group of rows, with an optional heading above and note below, like a grouped form.
struct SettingsGroup<Content: View>: View {
    var title: String?
    var footer: String?
    @ViewBuilder var content: Content

    private static var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 10.0, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6.0) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 4.0)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Self.shape.fill(Color.primary.opacity(0.04)))
            .overlay(Self.shape.strokeBorder(Color.primary.opacity(0.08)))
            if let footer {
                Text(footer)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4.0)
            }
        }
    }
}

/// A row: its label on the left, its control on the right.
struct SettingsRow<Control: View>: View {
    let label: String
    @ViewBuilder var control: Control

    init(_ label: String, @ViewBuilder control: () -> Control) {
        self.label = label
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 12.0) {
            Text(label)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8.0)
            control
        }
        .padding(.horizontal, 14.0)
        .padding(.vertical, 8.0)
        .frame(minHeight: 40.0)
    }
}

/// A row whose control is a switch.
struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool

    init(_ label: String, isOn: Binding<Bool>) {
        self.label = label
        _isOn = isOn
    }

    var body: some View {
        SettingsRow(label) {
            Toggle(label, isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }
}

/// Content that isn't a label and a control, such as cards or a preview, padded to sit in a group.
struct SettingsBlock<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14.0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The hairline between rows in a group.
struct SettingsDivider: View {
    var body: some View {
        Divider().padding(.leading, 14.0)
    }
}
