import AppKit
import CoreMedia
import ScreenCaptureKit

/// One frame of the loupe: the magnified window, the centre device pixel's colour, and, when
/// that pixel's point is all one colour, the point to read it as drawn from.
struct LoupeCapture {
    let image: CGImage
    let pixel: NSColor?
    let flatPoint: CGPoint?
}

// Screen capture for the Pro picker's loupe: what ScreenCaptureKit is asked for, and how its
// pixels are read. Static, so the Debug-only `pika://debug/sample` URL samples exactly as a
// pick does.
extension PickerLoupeController {
    /// Captures the magnifier window around `cursor` (AppKit coordinates) on `screen`: the image
    /// the loupe shows, and its centre pixel's colour. Shared by live picking and the Debug-only
    /// `pika://debug/sample` URL, so a test samples exactly as a pick does.
    static func captureWindow(
        around cursor: NSPoint, on screen: NSScreen, pixelCount: Int, filter: SCContentFilter
    ) async throws -> LoupeCapture {
        let scale = screen.backingScaleFactor

        // Capture ONLY a small window around the cursor — not the whole display (tens of MB per
        // frame on a large screen). But a `sourceRect` with a SUB-POINT origin makes
        // ScreenCaptureKit sample *between* pixels and softens the magnifier. So snap the rect to
        // WHOLE POINTS that fully enclose the magnifier window and capture at its exact
        // device-pixel size (1:1, no resample), then crop the exact window out of the result with
        // `CGImage.cropping` — a pure pixel op that keeps it hard-edged and the sample exact.
        let displayWpx = Int((screen.frame.width * scale).rounded())
        let displayHpx = Int((screen.frame.height * scale).rounded())
        // Magnifier window in device pixels (top-left origin), clamped so it stays on-screen.
        let localX = (cursor.x - screen.frame.minX) * scale
        let localYTop = (screen.frame.height - (cursor.y - screen.frame.minY)) * scale
        let half = pixelCount / 2
        let winX = min(max(0, Int(localX.rounded()) - half), max(0, displayWpx - pixelCount))
        let winY = min(max(0, Int(localYTop.rounded()) - half), max(0, displayHpx - pixelCount))

        // Whole-point rect (top-left origin, points) that encloses the window, so SCK samples on
        // point boundaries with no sub-point blend.
        let originPtX = (Double(winX) / scale).rounded(.down)
        let originPtY = (Double(winY) / scale).rounded(.down)
        let regionPtW = (Double(winX + pixelCount) / scale).rounded(.up) - originPtX
        let regionPtH = (Double(winY + pixelCount) / scale).rounded(.up) - originPtY

        let config = SCStreamConfiguration()
        config.sourceRect = CGRect(x: originPtX, y: originPtY, width: regionPtW, height: regionPtH)
        config.width = Int((regionPtW * scale).rounded())
        config.height = Int((regionPtH * scale).rounded())
        config.showsCursor = false

        // The point holding the sampled (centre) device pixel.
        let pointX = (Double(winX + pixelCount / 2) / scale).rounded(.down)
        let pointY = (Double(winY + pixelCount / 2) / scale).rounded(.down)

        let region = try await capture(filter: filter, configuration: config)
        // Crop the exact magnifier window out of the whole-point capture (pure pixel op).
        let originX = Int((originPtX * scale).rounded())
        let originY = Int((originPtY * scale).rounded())
        let cropped = region.cropping(
            to: CGRect(x: winX - originX, y: winY - originY, width: pixelCount, height: pixelCount)
        ) ?? region
        let devicePixel = centerPixelColor(of: cropped)

        // Where the point's device pixels are all one colour, the caller can read it as drawn
        // with `sourceColor(ofPointAt:filter:)`, so a colour beyond the display's gamut reads as
        // the system picker reads it. Where they differ (an edge, anti-aliasing, a hairline), the
        // exact device pixel stands. Not captured here: ScreenCaptureKit runs captures one at a
        // time, and a second capture every frame halved the loupe's frame rate (measured on a 5K
        // display: 135 ms a frame, from 68).
        let pixelsPerPoint = max(1, Int(scale.rounded()))
        let flat = isUniform(
            region, x: Int((pointX * scale).rounded()) - originX, y: Int((pointY * scale).rounded()) - originY,
            size: pixelsPerPoint
        )
        return LoupeCapture(image: cropped, pixel: devicePixel, flatPoint: flat ? CGPoint(x: pointX, y: pointY) : nil)
    }

    /// One point's colour, from a capture downscaled to a pixel per point.
    ///
    /// Measured on an MPG272UX QD-OLED (macOS 27): a full-resolution capture of 2pt or more reads a
    /// colour just beyond the panel's gamut as the nearest colour the panel can show (P3 red as
    /// `(1, 0, 0.09)` in P3), where a downscaled capture of any size reads it as drawn, `(1, 0, 0)`,
    /// which is also what the system picker returns. Colours inside the gamut read the same in
    /// both, to within a half-float step.
    static func sourceColor(ofPointAt point: CGPoint, filter: SCContentFilter) async throws -> NSColor? {
        let config = SCStreamConfiguration()
        config.sourceRect = CGRect(origin: point, size: CGSize(width: 1, height: 1))
        config.width = 1
        config.height = 1
        config.showsCursor = false
        return try centerPixelColor(of: await capture(filter: filter, configuration: config))
    }

    /// Whether the `size`×`size` block of pixels at (`x`, `y`) in `image` is all one colour.
    static func isUniform(_ image: CGImage, x left: Int, y top: Int, size: Int) -> Bool {
        guard left >= 0, top >= 0, left + size <= image.width, top + size <= image.height,
              let first = pixelColor(of: image, x: left, y: top)
        else { return false }
        for row in top ..< top + size {
            for column in left ..< left + size where (column, row) != (left, top) {
                guard let other = pixelColor(of: image, x: column, y: row),
                      other.isEqual(first)
                else { return false }
            }
        }
        return true
    }

    /// The space the half-float capture is in. Display P3 covers what Mac displays show, and the
    /// extended range holds anything beyond it rather than clipping. Measured: sRGB swatches read
    /// back exact, and a P3 swatch keeps its P3 value, where an extended sRGB capture clipped it.
    static let captureSpaceName = CGColorSpace.extendedLinearDisplayP3

    /// Half-float extended linear Display P3, whatever the colour space setting, so the only 8-bit
    /// rounding left is the readout's. `captureImage` ignores `pixelFormat` and always returns
    /// 8-bit BGRA, so this goes through a sample buffer.
    ///
    /// On macOS 15 it also asks for HDR values. With a display in HDR mode, an SDR capture squeezes
    /// the display's whole range into 0…1, so white reads at about 0.9 and every pick comes back
    /// darker than its source (measured: `#0e1829` read as `#0d1625`). In HDR values 1.0 is SDR
    /// white, so sRGB and P3 content reads back exactly; on an SDR display the two are the same.
    static func capture(
        filter: SCContentFilter, configuration config: SCStreamConfiguration
    ) async throws -> CGImage {
        config.pixelFormat = kCVPixelFormatType_64RGBAHalf
        config.colorSpaceName = captureSpaceName
        if #available(macOS 15.0, *) {
            config.captureDynamicRange = .hdrLocalDisplay
        }
        let sampleBuffer = try await SCScreenshotManager.captureSampleBuffer(
            contentFilter: filter, configuration: config
        )
        if let image = image(fromHalfFloat: sampleBuffer) { return image }
        // Not the format asked for; fall back to an 8-bit capture rather than no sample.
        config.colorSpaceName = CGColorSpace.displayP3
        if #available(macOS 15.0, *) {
            config.captureDynamicRange = .SDR
        }
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    /// A `kCVPixelFormatType_64RGBAHalf` capture as a CGImage, so the magnifier can draw it and
    /// `CGImage.cropping` can cut the sample window out of it, as with an 8-bit capture.
    static func image(fromHalfFloat sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = sampleBuffer.imageBuffer,
              CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_64RGBAHalf,
              // Tagged explicitly: an HDR capture carries no colour space attachment.
              let space = CGColorSpace(name: captureSpaceName)
        else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let data = Data(bytes: base, count: bytesPerRow * height) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.floatComponents.rawValue
                | CGBitmapInfo.byteOrder16Little.rawValue
        )
        return CGImage(
            width: CVPixelBufferGetWidth(pixelBuffer), height: height,
            bitsPerComponent: 16, bitsPerPixel: 64, bytesPerRow: bytesPerRow,
            space: space, bitmapInfo: bitmapInfo, provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }

    /// An IEEE 754 half-precision value. `Float16` isn't available on Intel Macs.
    static func float(fromHalf bits: UInt16) -> CGFloat {
        let sign: CGFloat = bits & 0x8000 == 0 ? 1 : -1
        let exponent = Int((bits >> 10) & 0x1F)
        let mantissa = CGFloat(bits & 0x3FF)
        switch exponent {
        case 0: return sign * mantissa * pow(2, -24)
        case 31: return mantissa == 0 ? sign * .infinity : .nan
        default: return sign * (1 + mantissa / 1024) * pow(2, CGFloat(exponent - 15))
        }
    }

    static func centerPixelColor(of image: CGImage) -> NSColor? {
        pixelColor(of: image, x: max(0, image.width / 2), y: max(0, image.height / 2))
    }

    static func pixelColor(of image: CGImage, x column: Int, y row: Int) -> NSColor? {
        let (x, y) = (column, row)
        // Read the raw pixel and build the colour in the image's *exact* colour space (the
        // one we captured in). `NSBitmapImageRep.colorAt` reinterprets
        // the pixel through an intermediate device/calibrated space, so the sampled colour
        // didn't match what was on screen and drifted when re-picking Pika's own rendered
        // swatch. Anything but the standard ScreenCaptureKit layout falls back to colorAt.
        func fallback() -> NSColor? {
            NSBitmapImageRep(cgImage: image).colorAt(x: x, y: y)
        }

        // The half-float capture (see `image(fromHalfFloat:)`): RGBA, 16-bit little-endian.
        if image.bitsPerComponent == 16, image.bitsPerPixel == 64,
           image.bitmapInfo.contains(.floatComponents),
           let cgColorSpace = image.colorSpace,
           let colorSpace = NSColorSpace(cgColorSpace: cgColorSpace),
           let data = image.dataProvider?.data,
           let ptr = CFDataGetBytePtr(data)
        {
            let offset = y * image.bytesPerRow + x * 8
            let channels = (0 ..< 3).map { channel in
                let at = offset + channel * 2
                return float(fromHalf: UInt16(ptr[at]) | UInt16(ptr[at + 1]) << 8)
            }
            return NSColor(colorSpace: colorSpace, components: channels + [1.0], count: 4)
        }

        guard image.bitsPerComponent == 8, image.bitsPerPixel == 32,
              let cgColorSpace = image.colorSpace,
              let colorSpace = NSColorSpace(cgColorSpace: cgColorSpace),
              let data = image.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data)
        else { return fallback() }

        // ScreenCaptureKit hands back 32-bit BGRA (little-endian, alpha-first); screen
        // pixels are opaque, so no un-premultiply is needed.
        let alphaFirst = image.alphaInfo == .premultipliedFirst || image.alphaInfo == .first
            || image.alphaInfo == .noneSkipFirst
        guard image.bitmapInfo.intersection(.byteOrderMask) == .byteOrder32Little, alphaFirst
        else { return fallback() }

        let offset = y * image.bytesPerRow + x * 4
        let blue = CGFloat(ptr[offset]) / 255.0
        let green = CGFloat(ptr[offset + 1]) / 255.0
        let red = CGFloat(ptr[offset + 2]) / 255.0
        return NSColor(colorSpace: colorSpace, components: [red, green, blue, 1.0], count: 4)
    }
}
