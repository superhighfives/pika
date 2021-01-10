import SwiftUI

struct NavigationMenu: View {
    @ViewBuilder
    func getMenu() -> some View {
        let icon = "gearshape"

        if #available(OSX 11.0, *) {
            Menu {
                NavigationMenuItems()
            } label: {
                IconImage(name: icon)
            }
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
        } else {
            MenuButton(label: HStack { Spacer(); IconImage(name: icon) }, content: {
                NavigationMenuItems()
            })
                .menuButtonStyle(BorderlessPullDownMenuButtonStyle())
                .padding(EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0))
                .edgesIgnoringSafeArea(.all)
                .fixedSize()
        }
    }

    var body: some View {
        getMenu()
            .frame(alignment: .leading)
            .padding(.horizontal, 16.0)
            .fixedSize()
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
