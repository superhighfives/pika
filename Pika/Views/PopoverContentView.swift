import Defaults
import SwiftUI

struct PopoverContentView: View {
    let eyedroppers: Eyedroppers

    @ObservedObject private var drawer = PopoverDrawerLayout.shared

    /// Content height with the history drawer closed.
    private static let baseHeight: CGFloat = 280
    var body: some View {
        // Grows by the drawer's height, so the swatches keep their size and the content clears
        // `PikaAdaptiveHeight.palettes`, below which `ContentView` hides the drawer.
        let height = Self.baseHeight + drawer.revealed
        // Always laid out with the drawer, pinned to the top, so the popover reveals or covers it
        // rather than squeezing the colours, and opening has no drawer to build first.
        let contentHeight = Self.baseHeight + ColorHistoryDrawer.height
        VStack(spacing: 0) {
            HStack {
                Spacer()
                NavigationMenu()
            }
            .padding(.horizontal, 12)
            // The same above and below, so the controls sit in the middle of the bar.
            .padding(.vertical, 7)
            Color.clear
                .frame(height: height)
                .overlay(alignment: .top) {
                    ContentView()
                        .environment(\.pikaShowsDrawer, true)
                        .frame(height: contentHeight)
                }
                .clipped()
        }
        .environmentObject(eyedroppers)
        .frame(width: 480)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

/// How much of the popover's palette drawer shows, driven from the setting rather than read by
/// the view. The popover takes its content's size without animating, so this animates the
/// reveal a display frame at a time, while the drawer stays laid out under the colours: they
/// never move, and the popover grows or shrinks over the drawer.
final class PopoverDrawerLayout: ObservableObject {
    static let shared = PopoverDrawerLayout()

    /// How much of the drawer the popover shows, from none to `ColorHistoryDrawer.height`.
    @Published private(set) var revealed: CGFloat = Defaults[.historyDrawerVisible] ? ColorHistoryDrawer.height : 0

    private var step: Timer?
    private var waitForMenu: NSObjectProtocol?

    private init() {
        Defaults.observe(.historyDrawerVisible, options: []) { [weak self] change in
            guard change.oldValue != change.newValue else { return }
            self?.animate(to: change.newValue ? ColorHistoryDrawer.height : 0)
        }.tieToLifetime(of: self)
    }

    private func animate(to target: CGFloat) {
        step?.invalidate()
        waitForMenu.map(NotificationCenter.default.removeObserver)
        waitForMenu = nil
        // An open menu (the View menu, toggling this) is placed from the popover's bottom edge,
        // so resizing under it moved the menu. The drawer follows once the menu closes.
        if RunLoop.current.currentMode == .eventTracking {
            waitForMenu = NotificationCenter.default.addObserver(
                forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main
            ) { [weak self] _ in
                // On the next pass: while this posts, the menu is still tracking.
                DispatchQueue.main.async {
                    self?.animate(to: Defaults[.historyDrawerVisible] ? ColorHistoryDrawer.height : 0)
                }
            }
            return
        }
        let start = revealed
        let duration = 0.25
        let began = CACurrentMediaTime()
        let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] timer in
            let progress = min((CACurrentMediaTime() - began) / duration, 1)
            // Ease in and out.
            let eased = progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
            let revealed = (start + (target - start) * eased).rounded()
            self?.set(revealed: revealed)
            if progress >= 1 {
                timer.invalidate()
                self?.step = nil
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        step = timer
    }

    /// Outside any SwiftUI animation: the View menu toggles inside one, which would slide the
    /// drawer against the popover's own movement.
    private func set(revealed: CGFloat) {
        guard self.revealed != revealed else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { self.revealed = revealed }
    }
}

extension EnvironmentValues {
    /// Whether the popover lays out its palette drawer, which it always does (`PopoverContentView`).
    var pikaShowsDrawer: Bool {
        get { self[PikaShowsDrawerKey.self] }
        set { self[PikaShowsDrawerKey.self] = newValue }
    }
}

private struct PikaShowsDrawerKey: EnvironmentKey {
    static let defaultValue = false
}
