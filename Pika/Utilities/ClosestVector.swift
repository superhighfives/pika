import Cocoa
import Defaults

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
        let color = val.usingColorSpace(Defaults[.colorSpace])!
        let colorArr = [Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255)]

        var minDistance = Int.max
        var index = 0

        // swiftlint:disable identifier_name
        for i in 0 ..< list.count {
            let distance = diff(colorArr, list[i])
            if distance < minDistance {
                minDistance = distance
                index = i
            }
        }
        // swiftlint:enable identifier_name

        // return and save in cache
        return index
    }
}
