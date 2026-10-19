import SwiftUI

struct HelpView: View {
    /// The shortcuts note names Pick pair by its default keys; show the user's binding instead.
    private var shortcutsDescription: String {
        let keys = pickPairKeys().joined()
        guard !keys.isEmpty else { return PikaText.textHelpShortcutsDescription }
        return PikaText.textHelpShortcutsDescription.replacingOccurrences(of: "[⌥⌘D]", with: "[\(keys)]")
    }

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Header

                VisualisationHeader(height: 180) {
                    Text(PikaText.textMenuHelp)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                .background(
                    GeometryReader { geo in
                        Color(red: 0.4, green: 0.0, blue: 0.7)
                            .frame(height: geo.size.height + 500)
                            .offset(y: -500)
                    }
                )
                Divider()

                HelpDescriptionRow(text: PikaText.textHelpDescription)
                Divider()

                // MARK: Basics

                HelpSectionHeader(title: PikaText.textHelpBasics)
                Divider()
                HelpBasicsGrid(entries: basics)
                VStack(spacing: 0) {
                    HelpExternalLinkRow(title: PikaText.textHelpReferenceWCAG, url: PikaConstants.wcagContrastURL, shorthand: "w3.org/…/contrast-minimum")
                    Divider().padding(.horizontal, 20)
                    HelpExternalLinkRow(title: PikaText.textHelpReferenceAPCA, url: PikaConstants.apcaGuideURL, shorthand: "git.apcacontrast.com/…")
                }
                .padding(.bottom, 10)
                Divider()

                // MARK: Keyboard Shortcuts

                HelpSectionHeader(title: PikaText.textHelpKeyboardShortcuts)
                Divider()
                HelpKeycapText(text: shortcutsDescription, keySize: 11)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                Divider()
                ForEach(shortcutGroups.indices, id: \.self) { gi in
                    let group = shortcutGroups[gi]
                    VStack(spacing: 0) {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        ForEach(group.entries.indices, id: \.self) { ei in
                            HelpShortcutRow(entry: group.entries[ei])
                            if ei < group.entries.count - 1 {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    if gi < shortcutGroups.count - 1 {
                        Divider()
                    }
                }
                Divider()

                // MARK: URL Triggers

                HelpSectionHeader(title: PikaText.textHelpURLTriggers)
                Divider()
                HelpDescriptionRow(text: PikaText.textHelpURLTriggersDescription)
                Divider()
                ForEach(urlGroups.indices, id: \.self) { gi in
                    let group = urlGroups[gi]
                    VStack(spacing: 0) {
                        HStack {
                            Text(group.title)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)

                        ForEach(group.entries.indices, id: \.self) { ei in
                            URLTriggerRow(url: group.entries[ei].url, description: group.entries[ei].description)
                            if ei < group.entries.count - 1 {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    if gi < urlGroups.count - 1 {
                        Divider()
                    }
                }
                Divider()

                // MARK: Colour Formats

                HelpSectionHeader(title: PikaText.textHelpFormats)
                Divider()
                VStack(spacing: 0) {
                    ForEach(formats.indices, id: \.self) { index in
                        FormatRow(name: formats[index].name, example: formats[index].example, shortcut: formats[index].shortcut)
                        if index < formats.count - 1 {
                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
                Divider()

                // MARK: Open Source

                HelpSectionHeader(title: PikaText.textHelpOpenSource)
                Divider()
                HelpDescriptionRow(text: PikaText.textHelpOpenSourceDescription)
                Divider()
                VStack(spacing: 0) {
                    HelpExternalLinkRow(title: PikaText.textHelpViewOnGitHub, url: PikaConstants.gitHubRepoURL, shorthand: "github.com/superhighfives/pika")
                    Divider().padding(.horizontal, 20)
                    HelpExternalLinkRow(title: PikaText.textMenuGitHubIssue, url: PikaConstants.gitHubIssueURL, shorthand: "github.com/…/issues")
                    Divider().padding(.horizontal, 20)
                    HelpExternalLinkRow(title: PikaText.textHelpSupportOnMAS, url: PikaConstants.macAppStoreURL, shorthand: "apps.apple.com/…/pika")
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
            .frame(width: 550, height: 700)
    }
}
