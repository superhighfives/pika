import SwiftUI

struct LinkButton: View {
    var title: String
    var link: String

    var body: some View {
        Button(title) {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }
        .buttonStyle(LinkButtonStyle())
    }
}

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 16.0) {
            ZStack(alignment: .bottom) {
                Visualisation()
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            AppVersion()
                .padding(EdgeInsets(top: -50, leading: 0, bottom: 0, trailing: 0))
            VStack(spacing: 20.0) {
                VStack(spacing: 0) {
                    KeyboardShortcutGrid()
                        .frame(height: 250.0)
                        .background(colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.2))
                }

                HStack(spacing: 5.0) {
                    HStack(spacing: 5.0) {
                        IconImage(name: "hand.thumbsup.fill")
                        Text(PikaText.textAboutBy)
                        LinkButton(title: "Charlie Gleason", link: PikaConstants.charlieGleasonWebsiteURL)
                    }
                    Spacer()
                    HStack(spacing: 20.0) {
                        LinkButton(
                            title: PikaText.textAboutWebsite,
                            link: PikaConstants.pikaWebsiteURL
                        )
                        LinkButton(
                            title: PikaText.textAboutGitHub,
                            link: PikaConstants.gitHubRepoURL
                        )
                        LinkButton(
                            title: PikaText.textMenuGitHubIssue,
                            link: PikaConstants.gitHubIssueURL
                        )
                    }
                    Spacer()
                    #if TARGET_MAS
                        HStack(spacing: 5.0) {
                            IconImage(name: "storefront.circle", resizable: true)
                                .foregroundColor(Color.secondary)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                            Text(PikaText.textAboutMacAppStore)
                                .foregroundColor(Color.secondary)
                        }
                    #endif
                    #if TARGET_SPARKLE
                        HStack(spacing: 5.0) {
                            IconImage(name: "arrow.down.circle", resizable: true)
                                .foregroundColor(Color.secondary)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                            Text(PikaText.textAboutDownloaded)
                                .foregroundColor(Color.secondary)
                        }
                    #endif
                }
                .padding(.horizontal, 20.0)
            }
            .padding(.bottom, 20.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .frame(width: 550, height: 700)
    }
}
