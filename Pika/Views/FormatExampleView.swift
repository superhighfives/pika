import SwiftUI
import Defaults

struct FormatExampleView: View {
	@Default(.customCopyFormat) var customColorFormat
	var copyFormat: CopyFormat
	@ObservedObject var eyedropper: Eyedropper
	@Environment(\.colorScheme) var colorScheme: ColorScheme

	var body: some View {
		let shadowColor: Color = eyedropper.color.getUIColor()
		let exampleText = getFormattedExampleText()

		VStack(alignment: .leading, spacing: 8.0) {
	
			VStack(alignment: .leading, spacing: 2) {
				placeholderRow(label: "{r}", description: "Red (0-255)")
				placeholderRow(label: "{g}", description: "Green (0-255)")
				placeholderRow(label: "{b}", description: "Blue (0-255)")
				placeholderRow(label: "{a}", description: "Opacity (0.0-1.0)")
			}
			.font(.caption)
			.foregroundColor(.secondary)
			
			HStack(alignment: .center, spacing: 8.0) {
				RoundedRectangle(cornerRadius: 2.0)
					.fill(Color(eyedropper.color))
					.shadow(color: Color(eyedropper.color).opacity(0.15), radius: 1, x: 0, y: 1)
					.overlay(
						RoundedRectangle(cornerRadius: 4.0)
							.stroke(colorScheme == .dark ? .black : .white, lineWidth: 1)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 4.0)
							.strokeBorder(shadowColor.opacity(0.5), lineWidth: 1)
					)
					.frame(width: 12.0, height: 12.0)
				
				Text("Output:").fixedSize().foregroundColor(.secondary)
					.font(.system(size: 11))
				
				exampleText
					.font(.system(size: 11))
					.fixedSize()
			}
			.padding(.horizontal, 8.0)
			.padding(.vertical, 8.0)
			.frame(maxWidth: 460.0, alignment: .leading)
			.clipShape(RoundedRectangle(cornerRadius: 4.0))
			.background(RoundedRectangle(cornerRadius: 4.0).fill(colorScheme == .dark
																 ? .black.opacity(0.1)
																 : .white.opacity(0.2))
			)
			.overlay(RoundedRectangle(cornerRadius: 4.0).stroke(Color.primary.opacity(0.1)))
		}
	}

	private func getFormattedExampleText() -> Text {
		let (red, green, blue, alpha) = eyedropper.color.toRGBAComponents()
		let redInt = Int(round(red * 255))
		let greenInt = Int(round(green * 255))
		let blueInt = Int(round(blue * 255))
		let alphaValue = round(alpha * 100) / 100

		let formattedString = customColorFormat
			.replacingOccurrences(of: "{r}", with: "§\(redInt)§")
			.replacingOccurrences(of: "{g}", with: "§\(greenInt)§")
			.replacingOccurrences(of: "{b}", with: "§\(blueInt)§")
			.replacingOccurrences(of: "{a}", with: "§\(alphaValue)§")

		let components = formattedString.components(separatedBy: "§")
		var resultText = Text("")

		for (index, component) in components.enumerated() {
			if index % 2 == 1 {
				switch component {
				case "\(redInt)":
					resultText = resultText + Text(component).foregroundColor(.red)
				case "\(greenInt)":
					resultText = resultText + Text(component).foregroundColor(.green)
				case "\(blueInt)":
					resultText = resultText + Text(component).foregroundColor(.blue)
				case "\(alphaValue)":
					resultText = resultText + Text(component).foregroundColor(.white)
				default:
					resultText = resultText + Text(component).foregroundColor(.gray)
				}
			} else {
				resultText = resultText + Text(component).foregroundColor(.gray)
			}
		}
		
		return resultText
	}
	
	private func placeholderRow(label: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 4) {
			Text(label)
				.foregroundColor(.white)
				.frame(width: 15, alignment: .trailing)
			Text("- \(description)")
				.foregroundColor(.gray)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

struct FormatExample_Previews: PreviewProvider {
	static var previews: some View {
		FormatExampleView(copyFormat: CopyFormat.css, eyedropper: Eyedroppers().foreground)
	}
}
