import SwiftUI

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
                AppVersion(displayOnTransparent: true)
                    .padding(.bottom, 32)
            }
            VStack(spacing: 0) {
                Divider()
                HelpExternalLinkRow(title: PikaText.textAboutWebsite, url: PikaConstants.pikaWebsiteURL, shorthand: "superhighfives.com/pika", verticalPadding: 10.0)
                Divider()
                HelpExternalLinkRow(title: PikaText.textAboutGitHub, url: PikaConstants.gitHubRepoURL, shorthand: "github.com/superhighfives/pika", verticalPadding: 10.0)
                Divider()
                HelpExternalLinkRow(title: PikaText.textMenuGitHubIssue, url: PikaConstants.gitHubIssueURL, shorthand: "github.com/…/issues", verticalPadding: 10.0)
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
                HelpExternalLinkRow(title: "\(PikaText.textAboutBy) Charlie Gleason", url: PikaConstants.charlieGleasonWebsiteURL, shorthand: "charliegleason.com", verticalPadding: 10.0)
                Divider()
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
