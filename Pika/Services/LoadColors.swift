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

struct RALColorName: Decodable {
    public var code: String
    public var nameEn: String
    public var nameZh: String
    public var hex: String
    public var color: NSColor {
        NSColor(hex: hex)
    }

    enum CodingKeys: String, CodingKey {
        case code
        case nameEn = "name_en"
        case nameZh = "name_zh"
        case hex
    }
}

struct RALResponseData: Decodable {
    var colors: [RALColorName]
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

func loadRALColors() -> [RALColorName]? {
    if let url = Bundle.main.url(forResource: "RALColors", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(RALResponseData.self, from: data)
            return jsonData.colors
        } catch {
            print("error:\(error)")
        }
    }
    return nil
}
