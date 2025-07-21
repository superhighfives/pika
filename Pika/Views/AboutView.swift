import Defaults
import SwiftData
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
                            Text("Mac App Store")
                                .foregroundColor(Color.secondary)
                        }
                    #endif
                    #if TARGET_SPARKLE
                        HStack(spacing: 5.0) {
                            IconImage(name: "arrow.down.circle", resizable: true)
                                .foregroundColor(Color.secondary)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 14, height: 14)
                            Text("Downloaded from the internet")
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

// MARK: - Color History Views

struct ColorHistory: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ColorPair.timestamp, order: .reverse) private var colorPairs: [ColorPair]
    @EnvironmentObject var eyedroppers: Eyedroppers
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            if colorPairs.isEmpty {
                VStack {
                    IconImage(name: "paintpalette")
                        .foregroundColor(.secondary)
                        .font(.system(size: 48))
                    Text("No Color History")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Color pairs will appear here as you use Pika")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(colorPairs, id: \.timestamp) { colorPair in
                        ColorHistoryRow(colorPair: colorPair) {
                            loadColorPair(colorPair)
                        }
                    }
                    .onDelete(perform: deleteColorPairs)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Color History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func loadColorPair(_ colorPair: ColorPair) {
        eyedroppers.foreground.set(colorPair.foreground)
        eyedroppers.background.set(colorPair.background)
        dismiss()
    }

    private func deleteColorPairs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(colorPairs[index])
            }
        }
    }
}

struct ColorHistoryRow: View {
    let colorPair: ColorPair
    let onTap: () -> Void
    @Default(.colorFormat) var colorFormat

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color(colorPair.foreground))
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)

                    Rectangle()
                        .fill(Color(colorPair.background))
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Foreground:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(colorPair.foreground.toFormat(format: colorFormat, style: .unformatted))
                            .font(.caption)
                            .monospaced()
                    }

                    HStack {
                        Text("Background:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(colorPair.background.toFormat(format: colorFormat, style: .unformatted))
                            .font(.caption)
                            .monospaced()
                    }
                }

                Spacer()

                Text(formatDate(colorPair.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .frame(width: 550, height: 700)
    }
}
