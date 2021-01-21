import SwiftUI

struct KeyboardShortcutGrid: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // TODO: Refactor
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                VStack(spacing: 0.0) {
                    HStack(spacing: 0.0) {
                        VStack {
                            Text("Copy foreground")
                            HStack(spacing: 4.0) {
                                KeyboardKey { Text("A") }
                                KeyboardKey { Text("B") }
                                KeyboardKey { Text("C") }
                            }
                        }
                        .frame(width: width / 2, height: height / 2)

                        Divider()
                            .frame(height: height / 2)

                        VStack {
                            Text("Copy foreground")
                            HStack(spacing: 4.0) {
                                KeyboardKey { Text("A") }
                                KeyboardKey { Text("B") }
                                KeyboardKey { Text("C") }
                            }
                        }
                        .frame(width: width / 2, height: height / 2)
                    }

                    Divider()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 0) {
                        VStack {
                            Text("Copy foreground")
                            HStack(spacing: 4.0) {
                                KeyboardKey { Text("A") }
                                KeyboardKey { Text("B") }
                                KeyboardKey { Text("C") }
                            }
                        }
                        .frame(width: width / 2, height: height / 2)

                        Divider()
                            .frame(height: height / 2)

                        VStack {
                            Text("Copy foreground")
                            HStack(spacing: 4.0) {
                                KeyboardKey { Text("A") }
                                KeyboardKey { Text("B") }
                                KeyboardKey { Text("C") }
                            }
                        }
                        .frame(width: width / 2, height: height / 2)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
        }
    }
}

struct KeyboardShortcutGrid_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutGrid()
    }
}
