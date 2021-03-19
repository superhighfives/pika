import SwiftUI

struct AppVersion: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    var body: some View {
        VStack(spacing: 10.0) {
            VStack(spacing: 5.0) {
                Image("AboutIcon")
                Text(NSLocalizedString("app.name", comment: "Pika"))
                    .font(.title)
            }
            VStack(spacing: 2.0) {
                let textVersion = NSLocalizedString("app.version", comment: "Version")
                let textBuild = NSLocalizedString("app.build", comment: "Build")
                let textUnknown = NSLocalizedString("app.unknown", comment: "Unknown")
                Text("\(textVersion) \(appVersion ?? textUnknown)")
                    .fontWeight(.semibold)
                Text("(\(textBuild) \(buildNumber ?? textUnknown))")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct VersionView_Previews: PreviewProvider {
    static var previews: some View {
        AppVersion()
    }
}
