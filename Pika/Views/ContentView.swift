import SwiftUI


struct EyedropperButtonStyle: ButtonStyle {
  var color: Color
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
      .background(configuration.isPressed ? Color.white : color)
      .padding(0.0)
  }
}

struct ContentView: View {
  @ObservedObject var eyedropperForeground = Eyedropper(title: "Foreground", color: Color(NSColor.random()))
  @ObservedObject var eyedropperBackground = Eyedropper(title: "Background", color: Color(NSColor.random()))
  
  let pasteboard = NSPasteboard.general
  
  var body: some View {
    let eyedroppers = [eyedropperForeground, eyedropperBackground]
    
    VStack(spacing: 0) {
      
      HStack(spacing: 0.0) {
        Divider()
        ForEach(eyedroppers, id: \.title) { eyedropper in
          let textColor = eyedropper.color.isDark ? Color.white : Color.black
          Button(action: {eyedropper.start()}) {
            VStack(alignment: .leading) {
              Text(eyedropper.title)
                .font(.caption)
                .bold()
                .foregroundColor(textColor.opacity(0.5))
              Text(eyedropper.color.toHex)
                .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          .buttonStyle(EyedropperButtonStyle(color: Color(eyedropper.color)))
          .contextMenu {
            Button(action: {
              pasteboard.clearContents()
              pasteboard.setString(eyedropper.color.toHex, forType: .string)
            }) {
              Text("Copy color hex")
            }
          }
          Divider()
        }
      }
      
      Divider()
      
      VStack(alignment: .center) {
        Text("Contrast ratio")
          .font(.caption)
          .bold()
          .foregroundColor(.gray)
        Text(Double(round(100 * eyedropperForeground.color.contrastRatio(with: eyedropperBackground.color)) / 100).description)
      }
      .frame(maxWidth: .infinity)
      .padding(.all, 10.0)
    }
  }  
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
