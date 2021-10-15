import Defaults
import SwiftUI

struct NavigationMenu: View {
    @Default(.colorFormat) var colorFormat

    // These are a hack to trigger a redraw on OSX 11.0 - otherwise the
    // button displays wtih 50% opacity until you interact with it. If
    // anyone knows of a better way to do this, let me know.
    @State var once: Bool = false
    @State var showMenu: Bool = true

    @ViewBuilder
    func getMenu() -> some View {
        if showMenu {
            Menu {
                NavigationMenuItems()
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
            .onAppear {
                if !once {
                    self.showMenu.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showMenu.toggle()
                    }
                }
                once = true
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker(NSLocalizedString("preferences.format.title", comment: "Color Format"), selection: $colorFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { value in
                    Text(value.rawValue)
                }
            }
            .offset(y: 1.0)
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()

            getMenu()
                .frame(alignment: .leading)
                .padding(.trailing, 10.0)
                .padding(.leading, 5.0)
                .fixedSize()
        }
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
