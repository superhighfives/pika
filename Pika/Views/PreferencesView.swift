import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @Default(.colorFormat) var colorFormat
    @Default(.hideMenuBarIcon) var hideMenuBarIcon
    @Default(.betaUpdates) var betaUpdates
    @State var colorSpace: NSColorSpace = Defaults[.colorSpace]

    func getColorSpaces() -> ([NSColorSpace], [NSColorSpace]) {
        var availableSpaces = NSColorSpace.availableColorSpaces(with: .rgb).unique()
        var primarySpaces: [NSColorSpace] = []

        for space in availableSpaces {
            if space == NSColorSpace.sRGB || space == NSColorSpace.adobeRGB1998 || space == NSColorSpace.displayP3 {
                guard let index = availableSpaces.firstIndex(of: space) else { continue }
                primarySpaces.append(space)
                availableSpaces.remove(at: index)
            }
        }

        return (primarySpaces, availableSpaces)
    }

    var body: some View {
        let (primarySpaces, availableSpaces) = self.getColorSpaces()

        HStack(spacing: 0) {
            Group {
                AppVersion()
            }
            .frame(maxWidth: 180.0, maxHeight: .infinity)
            .background(VisualEffect(
                material: NSVisualEffectView.Material.sidebar,
                blendingMode: NSVisualEffectView.BlendingMode.behindWindow
            ))

            Divider()

            VStack(alignment: .leading, spacing: 10.0) {
                // Colour Format
                Section(header: Text("Colour Format").font(.system(size: 16))) {
                    VStack(alignment: .leading, spacing: 15.0) {
                        Text("Set your preferred display format for colors")
                        Picker("Colour Format", selection: $colorFormat) {
                            ForEach(ColorFormat.allCases, id: \.self) { value in
                                Text(value.rawValue)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .horizontalRadioGroupLayout()
                        .labelsHidden()
                    }

                    Spacer()
                        .frame(height: 0.0)

                    VStack(alignment: .leading, spacing: 15.0) {
                        Text("Set your RGB color space")
                        Picker("Color Space", selection:
                            $colorSpace.onChange(perform: { Defaults[.colorSpace] = $0 })) {
                            ForEach(primarySpaces, id: \.self) { value in
                                Text(value.localizedName!)
                                    .tag(value)
                            }
                            Divider()
                            ForEach(availableSpaces, id: \.self) { value in
                                Text(value.localizedName!)
                                    .tag(value)
                            }
                        }
                        .labelsHidden()
                    }
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 10.0)

                // Global Shortcut
                Section(header: Text("Global Shortcut").font(.system(size: 16))) {
                    VStack(alignment: .leading, spacing: 15.0) {
                        Text("Set a global hot key shortcut to invoke Pika")
                        KeyboardShortcuts.Recorder(for: .togglePika)
                    }
                }
                .padding(.horizontal, 24.0)

                Divider()
                    .padding(.vertical, 10.0)

                // Launch at login
                Section(header: Text("Startup Settings").font(.system(size: 16))) {
                    LaunchAtLogin.Toggle {
                        Text("Launch at login")
                    }
                    Toggle(isOn: $hideMenuBarIcon) {
                        Text("Hide menu bar icon")
                    }
                    Toggle(isOn: $betaUpdates) {
                        Text("Subscribe to beta releases")
                    }
                }
                .padding(.horizontal, 24.0)
            }
            .padding(.all, 0.0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
