import SwiftUI

struct TouchBarVisual: View {
    var body: some View {
        ZStack {
            Visualisation()
                .frame(height: 220.0)

                .clipped()
                .frame(height: 30.0, alignment: .bottom)
                .layoutPriority(1)
            HStack {
                Image("AppSplash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 500.0, maxHeight: 30.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(10)
    }
}

struct TouchBarVisual_Previews: PreviewProvider {
    static var previews: some View {
        TouchBarVisual()
    }
}
