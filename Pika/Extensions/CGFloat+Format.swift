import CoreGraphics

extension CGFloat {
    /// Formats the value with up to `maxDecimalPlaces` decimal places, stripping trailing zeros.
    /// e.g. 0.5000 → "0.5", 0.0000 → "0", 56.78 → "56.78"
    func strippedDecimalString(maxDecimalPlaces: Int) -> String {
        let formatted = String(format: "%.\(maxDecimalPlaces)f", self)
        guard formatted.contains(".") else { return formatted }
        var result = formatted
        while result.hasSuffix("0") { result.removeLast() }
        if result.hasSuffix(".") { result.removeLast() }
        return result
    }
}
