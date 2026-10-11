import AppKit
import Cocoa

public class ClosestVector {
    public var list: [[Int]]

    public init(_ list: [[Int]]) {
        self.list = list
    }

    public func diff(_ val1: [Int], _ val2: [Int]) -> Int {
        (val1[0] - val2[0]) * (val1[0] - val2[0]) +
            (val1[1] - val2[1]) * (val1[1] - val2[1]) +
            (val1[2] - val2[2]) * (val1[2] - val2[2])
    }

    public func compare(_ val: NSColor) -> (Int) {
        guard let color = val.usingColorSpace(.sRGB) else { return 0 }
        // Quantise with the same rounded helper used to build the named-color
        // database (see Eyedropper + toRGB8BitArray), so the query and the
        // database agree on every 8-bit bucket instead of truncate-vs-round.
        let colorArr = color.toRGB8BitArray()

        var minDistance = Int.max
        var index = 0

        for idx in 0 ..< list.count {
            let distance = diff(colorArr, list[idx])
            if distance < minDistance {
                minDistance = distance
                index = idx
            }
        }

        return index
    }
}
