import Cocoa

extension Sequence {
    func unique() -> [Iterator.Element] where Iterator.Element: Hashable {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
