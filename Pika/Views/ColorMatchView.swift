import Defaults
import SwiftUI

/// Runs Check a Color's own pick: a colour of its own, separate from the app's foreground and
/// background, which a pick here never touches.
final class ColorMatchModel: ObservableObject {
    @Published var picked: NSColor?
    @Published var isPicking = false
    /// The Check a Color window, hidden while picking so it isn't in the way.
    weak var window: NSWindow?
    private var session: ColorPickSession?

    func pick() {
        guard !isPicking else { return }
        let session: ColorPickSession
        if Defaults[.pickerStyle] == .custom, CustomColorPickSession.isAvailable {
            let custom = CustomColorPickSession()
            custom.previewsIntoApp = false
            session = custom
        } else {
            session = SystemColorPickSession()
        }
        self.session = session
        isPicking = true
        window?.orderOut(nil)
        session.begin(target: .foreground, comparison: nil, willChain: false) { [weak self] color in
            guard let self else { return }
            if let color {
                picked = color.usingColorSpace(.extendedSRGB) ?? color
            }
            isPicking = false
            self.session = nil
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }
    }
}

/// "Colors don't match?": pick a colour, enter the hex you expected, and see how each likely
/// colour space reads the pick, with the one to switch to.
struct ColorMatchView: View {
    @ObservedObject var model: ColorMatchModel
    @State private var expected = ""
    @State private var currentSpace = Defaults[.colorSpace]

    private var expectedHex: UInt32? {
        NSColor.fromHex(expected, in: .sRGB)?.toHex(in: .sRGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            Text(PikaText.textMatchIntro)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12.0) {
                SwatchCard(title: PikaText.textMatchPicked, color: model.picked, placeholder: "eyedropper") {
                    Button {
                        model.pick()
                    } label: {
                        Label(
                            model.picked == nil ? PikaText.textMatchPickFirst : PikaText.textMatchPick,
                            systemImage: "eyedropper"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(model.isPicking)
                }
                SwatchCard(
                    title: PikaText.textMatchExpectedTitle,
                    color: expectedHex.flatMap { NSColor.fromHex(String(format: "%06x", $0), in: .sRGB) },
                    placeholder: "number"
                ) {
                    TextField("#0e1829", text: $expected)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .accessibilityLabel(PikaText.textMatchExpected)
                }
            }

            if let picked = model.picked, let expectedHex {
                let matches = ColorSpaceMatcher.compare(picked, expected: expectedHex)
                ResultsList(matches: matches, currentSpace: currentSpace)
                Summary(matches: matches, currentSpace: currentSpace)
            } else {
                Text(PikaText.textMatchEmpty)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 44.0)
            }
        }
        .padding(24.0)
        .frame(width: 460.0, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            if Defaults[.colorSpace] != currentSpace { currentSpace = Defaults[.colorSpace] }
        }
    }
}

/// A titled swatch with one control under it.
private struct SwatchCard<Control: View>: View {
    let title: String
    let color: NSColor?
    let placeholder: String
    @ViewBuilder let control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            ZStack {
                if let color {
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .fill(Color(color))
                } else {
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .fill(.quaternary.opacity(0.5))
                    RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                        .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    Image(systemName: placeholder)
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .frame(height: 72.0)
            .animation(.easeInOut(duration: 0.2), value: color.map { Color($0) })
            control
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Each candidate space's reading of the pick, closest first.
private struct ResultsList: View {
    let matches: [ColorSpaceMatch]
    let currentSpace: NSColorSpace

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(matches.enumerated()), id: \.element.space) { index, match in
                if index > 0 { Divider().padding(.leading, 12.0) }
                HStack(spacing: 8.0) {
                    Text(ColorSpacePreference.name(of: match.space))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if match.space == currentSpace {
                        Text(PikaText.textMatchCurrentBadge)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6.0)
                            .padding(.vertical, 2.0)
                            .background(Capsule().fill(.quaternary))
                    }
                    Spacer(minLength: 12.0)
                    Text(String(format: "#%06x", match.hex))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    status(match)
                        .frame(width: 128.0, alignment: .trailing)
                }
                .padding(.horizontal, 12.0)
                .padding(.vertical, 8.0)
            }
        }
        .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous).fill(.quinary))
        .overlay(
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func status(_ match: ColorSpaceMatch) -> some View {
        if match.isMatch {
            Label(match.distance == 0 ? PikaText.textMatchExact : PikaText.textMatchClose,
                  systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout.weight(.medium))
        } else {
            Text(String(format: PikaText.textMatchOff, match.distance))
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }
}

/// The verdict, and what to do about it.
private struct Summary: View {
    let matches: [ColorSpaceMatch]
    let currentSpace: NSColorSpace

    var body: some View {
        let matching = matches.filter(\.isMatch)
        HStack(alignment: .center, spacing: 10.0) {
            if matching.contains(where: { $0.space == currentSpace }) {
                icon("checkmark.seal.fill", .green)
                message(PikaText.textMatchCurrent)
                Spacer(minLength: 0)
            } else if let best = matching.first {
                let name = ColorSpacePreference.name(of: best.space)
                icon("arrow.triangle.2.circlepath", .accentColor)
                message(String(format: PikaText.textMatchOther, name))
                Spacer(minLength: 12.0)
                Button(String(format: PikaText.textMatchUse, name)) {
                    ColorSpacePreference.select(Self.option(for: best.space))
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                icon("exclamationmark.triangle.fill", .orange)
                message(PikaText.textMatchNone)
                Spacer(minLength: 12.0)
                Link(PikaText.textMatchLearn, destination: URL(string: PikaConstants.colorSpaceHelpURL)!)
            }
        }
    }

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.title3)
            .foregroundStyle(color)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// A display's own profile is offered as "Match display", so it keeps following the screen.
    static func option(for space: NSColorSpace) -> ColorSpaceOption {
        if !ColorSpacePreference.isCommon(space), NSScreen.screens.contains(where: { $0.colorSpace == space }) {
            return .matchDisplay
        }
        return .space(space)
    }
}
