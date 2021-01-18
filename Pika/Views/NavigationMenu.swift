import SwiftUI

struct NavigationMenu: View {
    // These are a hack to trigger a redraw on OSX 11.0 - otherwise the
    // button displays wtih 50% opacity until you interract with it. If
    // anyone knows of a better way to do this, let me know.
    @State var once: Bool = false
    @State var showMenu: Bool = true

    @ViewBuilder
    func getMenu() -> some View {
        let icon = "gearshape"

        if #available(OSX 11.0, *) {
            if showMenu {
                Menu {
                    NavigationMenuItems()
                } label: {
                    IconImage(name: icon)
                }
                .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
                .onAppear {
                    if !once {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.showMenu.toggle()
                        }
                        self.showMenu.toggle()
                    }
                    once = true
                }
            }
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
        HStack {
            getMenu()
                .frame(alignment: .leading)
                .padding(.horizontal, 16.0)
                .fixedSize()
        }
    }
}

struct ToolbarButtons_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMenu()
    }
}
