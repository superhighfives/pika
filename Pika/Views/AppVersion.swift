import SwiftUI

struct AppVersion: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    var displayOnTransparent = false
    var body: some View {
        VStack(spacing: 10.0) {
            VStack(spacing: 5.0) {
                Image("AboutIcon")
                Text(PikaText.textAppName)
                    .font(.title)
                    .foregroundColor(colorScheme == .light && !displayOnTransparent ? .black : .white)
                    .modify {
                        if colorScheme == .dark || displayOnTransparent {
                            $0.shadow(color: Color.black.opacity(0.3),
                                      radius: 0,
                                      x: 0,
                                      y: 2)
                        } else {
                            $0
                        }
                    }
            }
            VStack(spacing: 2.0) {
                let textVersion = PikaText.textAboutVersion
                let textBuild = PikaText.textAboutBuild
                let textUnknown = PikaText.textAboutUnknown
                Text("\(textVersion) \(appVersion ?? textUnknown)")
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .light && !displayOnTransparent ? .black : .white)
                    .modify {
                        if colorScheme == .dark || displayOnTransparent {
                            $0.shadow(color: Color.black.opacity(0.3),
                                      radius: 0,
                                      x: 0,
                                      y: 2)
                        } else {
                            $0
                        }
                    }

                Text("(\(textBuild) \(buildNumber ?? textUnknown))")
                    .foregroundColor(colorScheme == .light && !displayOnTransparent ? .black : .white).opacity(0.5)
                    .modify {
                        if colorScheme == .dark || displayOnTransparent {
                            $0.shadow(color: Color.black.opacity(0.3),
                                      radius: 0,
                                      x: 0,
                                      y: 2)
                        } else {
                            $0
                        }
                    }
            }
        }
    }
}

struct VersionView_Previews: PreviewProvider {
    static var previews: some View {
        AppVersion()
    }
}
