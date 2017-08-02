import Bits

public final class Loop: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        guard case .dictionary(var dict) = context else {
            return nil
        }

        let body = try parsed.requireBody()
        try parsed.requireParameterCount(2)
        let array = parsed.parameters[0].array ?? []
        let key = parsed.parameters[1].string ?? ""

        var string: String = ""

        for (i, item) in array.enumerated() {
            let isLast = i == array.count - 1
            let loop = Data.dictionary([
                "index": .int(i),
                "isFirst": .bool(i == 0),
                "isLast": .bool(isLast)
            ])
            dict["loop"] = loop
            dict[key] = item
            let temp = Data.dictionary(dict)
            let bytes = try renderer.render(body, context: temp)
            string.append(bytes.makeString())
        }
        return .string(string)
    }
}


