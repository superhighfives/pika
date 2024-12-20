import Defaults
import SwiftUI

struct NavigationMenu: View {
    @Default(.colorFormat) var colorFormat

    var body: some View {
        HStack(spacing: 0) {
            Picker(PikaText.textFormatTitle, selection: $colorFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Text(value.rawValue)
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
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
            .frame(alignment: .leading)
            .padding(.trailing, 10.0)
            .padding(.leading, 5.0)
            .fixedSize()

            let values = ColorFormat.allCases.map { $0 }
            HStack {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Button(value.rawValue, action: {
                        colorFormat = value
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
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
