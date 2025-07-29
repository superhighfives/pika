import Defaults
import SwiftUI

struct NavigationMenu: View {
    @Default(.colorFormat) var colorFormat
    @Default(.copyFormat) var copyFormat

    func isFormatDisabled(_ format: ColorFormat) -> Bool {
        if copyFormat == .swiftUI {
            return PikaConstants.disabledFormats.contains(format)
        }
        return false
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker(PikaText.textFormatTitle, selection: $colorFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Text(value.rawValue)
                        .selectionDisabled(isFormatDisabled(value))
                }
            }
            .offset(y: 1.0)
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            Menu {
                NavigationMenuItems()
            } label: {
                IconImage(name: "gearshape")
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .menuIndicator(.visible)
            .frame(alignment: .leading)
            .padding(.trailing, 10.0)
            .padding(.leading, 5.0)
            .fixedSize()

            let values = ColorFormat.allCases.map { $0 }
            HStack {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Button(value.rawValue, action: {
                        if !isFormatDisabled(value) {
                            colorFormat = value
                        }
                    }).keyboardShortcut(
                        KeyEquivalent(
                            Character("\(values.firstIndex(of: value)! + 1)")
                        ), modifiers: .command
                    )
                }
            }
            .opacity(0)
            .frame(width: 0, height: 0)
            .padding(0)
        }
        .onChange(of: copyFormat) {
            if copyFormat == .swiftUI {
                if PikaConstants.disabledFormats.contains(colorFormat) {
                    colorFormat = .rgb
                }
            }
        }
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
