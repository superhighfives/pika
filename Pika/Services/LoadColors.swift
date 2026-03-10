import Cocoa

struct ColorName: Decodable {
    public var name: String
    public var hex: String
    public var color: NSColor {
        NSColor(hex: hex)
    }
}

struct ResponseData: Decodable {
    var colors: [ColorName]
}

func loadColors() -> [ColorName]? {
    if let url = Bundle.main.url(forResource: "ColorNames", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(ResponseData.self, from: data)
            return jsonData.colors
        } catch {
            print("error:\(error)")
        }
    }
    return nil
}
