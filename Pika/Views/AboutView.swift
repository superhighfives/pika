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
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Visualisation()
                    .frame(height: 200)
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.5)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                AppVersion()
                    .padding(.bottom, 16)
            }
            VStack(spacing: 0) {
                Divider()
                LinkButton(title: PikaText.textAboutWebsite, link: PikaConstants.pikaWebsiteURL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 10.0)
                Divider()
                LinkButton(title: PikaText.textAboutGitHub, link: PikaConstants.gitHubRepoURL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 10.0)
                Divider()
                LinkButton(title: PikaText.textMenuGitHubIssue, link: PikaConstants.gitHubIssueURL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 10.0)
                Divider()
                #if TARGET_MAS
                    HStack(spacing: 5.0) {
                        IconImage(name: "storefront.circle", resizable: true)
                            .foregroundColor(Color.secondary)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text(PikaText.textAboutMacAppStore)
                            .foregroundColor(Color.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 10.0)
                    Divider()
                #endif
                #if TARGET_SPARKLE
                    HStack(spacing: 5.0) {
                        IconImage(name: "arrow.down.circle", resizable: true)
                            .foregroundColor(Color.secondary)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                        Text(PikaText.textAboutDownloaded)
                            .foregroundColor(Color.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20.0)
                    .padding(.vertical, 10.0)
                    Divider()
                #endif
                HStack(spacing: 5.0) {
                    IconImage(name: "hand.thumbsup.fill")
                    Text(PikaText.textAboutBy)
                    LinkButton(title: "Charlie Gleason", link: PikaConstants.charlieGleasonWebsiteURL)
                    Spacer()
                }
                .padding(.horizontal, 20.0)
                .padding(.vertical, 10.0)
                Divider()
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .frame(width: 400)
    }
}
