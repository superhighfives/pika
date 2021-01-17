import Cocoa

public struct CodableColorSpace: Identifiable, Hashable {
    public var id: NSColorSpace { colorSpace }
    var colorSpace: NSColorSpace
    public static var allCases: [NSColorSpace] {
        NSColorSpace.availableColorSpaces(with: .rgb)
    }
}

extension CodableColorSpace: Encodable {
    public func encode(to encoder: Encoder) throws {
        let nsCoder = NSKeyedArchiver(requiringSecureCoding: true)
        colorSpace.encode(with: nsCoder)
        var container = encoder.unkeyedContainer()
        try container.encode(nsCoder.encodedData)
    }
}

extension CodableColorSpace: Decodable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let decodedData = try container.decode(Data.self)
        let nsCoder = try NSKeyedUnarchiver(forReadingFrom: decodedData)
        guard let colorSpace = NSColorSpace(coder: nsCoder) else {
            struct UnexpectedlyFoundNilError: Error {}
            throw UnexpectedlyFoundNilError()
        }

        self.colorSpace = colorSpace
    }
}

public extension NSColorSpace {
    func codable() -> CodableColorSpace {
        CodableColorSpace(colorSpace: self)
    }
}
