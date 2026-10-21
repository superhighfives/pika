import Defaults
import SwiftUI

/// "Colors don't match?": the user enters the hex they expected for a picked colour, and this
/// shows how each likely colour space reads the pick, with the one to switch to.
struct ColorMatchView: View {
    @EnvironmentObject var eyedroppers: Eyedroppers
    @State private var target: Eyedropper.Types = .foreground

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text(PikaText.textMatchIntro)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12.0) {
                Picker("", selection: $target) {
                    Text(Eyedropper.Types.foreground.description).tag(Eyedropper.Types.foreground)
                    Text(Eyedropper.Types.background.description).tag(Eyedropper.Types.background)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer()
                Button(PikaText.textMatchPick) {
                    NSApp.sendAction(target.pickSelector, to: nil, from: nil)
                }
            }

            ColorMatchResults(eyedropper: target == .foreground ? eyedroppers.foreground : eyedroppers.background)
                .id(target)
        }
        .padding(20.0)
        .padding(.top, 12.0)
        .frame(width: 440, alignment: .topLeading)
    }
}

private struct ColorMatchResults: View {
    @ObservedObject var eyedropper: Eyedropper
    @State private var expected = ""
    @State private var currentSpace = Defaults[.colorSpace]
    @Environment(\.colorScheme) private var colorScheme

    private var expectedHex: UInt32? {
        guard let color = NSColor.fromHex(expected, in: .sRGB) else { return nil }
        return color.toHex(in: .sRGB)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            HStack(alignment: .bottom, spacing: 12.0) {
                RoundedRectangle(cornerRadius: 6.0)
                    .fill(Color(eyedropper.color))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6.0)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(PikaText.textMatchExpected)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("#0e1829", text: $expected)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 140)
                        .accessibilityLabel(PikaText.textMatchExpected)
                }
            }

            if let expectedHex {
                let matches = ColorSpaceMatcher.compare(eyedropper.color, expected: expectedHex)
                Grid(alignment: .leading, horizontalSpacing: 16.0, verticalSpacing: 6.0) {
                    ForEach(matches, id: \.space) { match in
                        GridRow {
                            HStack(spacing: 4.0) {
                                Text(ColorSpacePreference.name(of: match.space))
                                if match.space == currentSpace {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(String(format: "#%06x", match.hex))
                                .font(.system(.body, design: .monospaced))
                            Text(status(of: match))
                                .foregroundStyle(match.isMatch ? Color.green : Color.secondary)
                        }
                    }
                }
                summary(for: matches)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            if Defaults[.colorSpace] != currentSpace { currentSpace = Defaults[.colorSpace] }
        }
    }

    private func status(of match: ColorSpaceMatch) -> String {
        if match.distance == 0 { return PikaText.textMatchExact }
        if match.isMatch { return PikaText.textMatchClose }
        return String(format: PikaText.textMatchOff, match.distance)
    }

    @ViewBuilder
    private func summary(for matches: [ColorSpaceMatch]) -> some View {
        let matching = matches.filter(\.isMatch)
        if matching.contains(where: { $0.space == currentSpace }) {
            Text(PikaText.textMatchCurrent)
                .fixedSize(horizontal: false, vertical: true)
        } else if let best = matching.first {
            let name = ColorSpacePreference.name(of: best.space)
            HStack(spacing: 12.0) {
                Text(String(format: PikaText.textMatchOther, name))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(String(format: PikaText.textMatchUse, name)) {
                    ColorSpacePreference.select(Self.option(for: best.space))
                }
                .keyboardShortcut(.defaultAction)
            }
        } else {
            VStack(alignment: .leading, spacing: 6.0) {
                Text(PikaText.textMatchNone)
                    .fixedSize(horizontal: false, vertical: true)
                Link(PikaText.textMatchLearn, destination: URL(string: PikaConstants.colorSpaceHelpURL)!)
            }
        }
    }

    /// A display's own profile is offered as "Match display", so it keeps following the screen.
    static func option(for space: NSColorSpace) -> ColorSpaceOption {
        if !ColorSpacePreference.isCommon(space), NSScreen.screens.contains(where: { $0.colorSpace == space }) {
            return .matchDisplay
        }
        return .space(space)
    }
}
