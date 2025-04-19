import Cocoa

extension NSColor {
    struct APCA {
        var value: CGFloat
        var level: String
    }

    func APCACompliance(with color: NSColor) -> APCA {
        let apcaValue = calculateAPCA(with: color)
        let level = getAPCALevel(value: apcaValue)
        
        return APCA(
            value: apcaValue,
            level: level
        )
    }
    
    func APCAcontrastValue(with color: NSColor) -> String {
        let value = calculateAPCA(with: color)
        let number = NSNumber(value: value)

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2

        let s = numberFormatter.string(from: number)
        return s!
    }
    
    private func calculateAPCA(with color: NSColor) -> CGFloat {
        let fgRGB = toRGBAComponents()
        let bgRGB = color.toRGBAComponents()
        
        // Convert to sRGB components in 0-255 range
        let fg = [fgRGB.r * 255, fgRGB.g * 255, fgRGB.b * 255]
        let bg = [bgRGB.r * 255, bgRGB.g * 255, bgRGB.b * 255]
        
        // Calculate luminance for both colors
        let yfg = sRGBtoY(fg)
        let ybg = sRGBtoY(bg)
        
        var c = 1.14
        
        if ybg > yfg {
            c *= pow(ybg, 0.56) - pow(yfg, 0.57)
        } else {
            c *= pow(ybg, 0.65) - pow(yfg, 0.62)
        }
        
        if abs(c) < 0.1 {
            return 0
        } else if c > 0 {
            c -= 0.027
        } else {
            c += 0.027
        }
        
        return c * 100
    }
    
    private func sRGBtoY(_ srgb: [CGFloat]) -> CGFloat {
        let r = pow(srgb[0] / 255, 2.4)
        let g = pow(srgb[1] / 255, 2.4)
        let b = pow(srgb[2] / 255, 2.4)
        var y = 0.2126729 * r + 0.7151522 * g + 0.072175 * b
        
        if y < 0.022 {
            y += pow(0.022 - y, 1.414)
        }
        return y
    }
    
    private func getAPCALevel(value: CGFloat) -> String {
        let absValue = abs(value)
        
        switch absValue {
        case 0..<15: return "Fail"
        case 15..<30: return "AA"
        case 30..<45: return "AAA"
        case 45..<60: return "AAA+"
        case 60...: return "Super"
        default: return "Unknown"
        }
    }
    
    func toAPCACompliance(with color: NSColor) -> (NSColor.APCA) {
        APCACompliance(with: color)
    }
}
