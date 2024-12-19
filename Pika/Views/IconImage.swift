import SwiftUI

struct IconImage: View {
    var name: String
    var resizable: Bool = false

    var body: some View {
        let image = Image(systemName: name)

        return image
            .modify { (image: Image) -> Image in
                if resizable {
                    return image
                        .resizable()
                } else {
                    return image
                }
            }
    }
}
