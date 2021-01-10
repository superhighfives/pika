import SwiftUI

struct IconImage: View {
    var name: String

    var body: some View {
        if #available(OSX 11.0, *) {
            return Image(systemName: name)
        } else {
            return Image(name)
        }
    }
}
