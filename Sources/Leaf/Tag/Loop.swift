public final class Loop: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Context? {
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
            let loop = Context.dictionary([
                "index": .int(i),
                "isFirst": .bool(i == 0),
                "isLast": .bool(isLast)
            ])
            dict["loop"] = loop
            dict[key] = item
            let temp = Context.dictionary(dict)
            let serializer = Serializer(ast: body, renderer: renderer, context: temp)
            let bytes = try serializer.serialize()
            guard let sub = String(data: bytes, encoding: .utf8) else {
                throw "could not convert data to string"
            }
            string.append(sub)
        }

        return .string(string)
    }
}


