public final class Var: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Context? {
        guard case .dictionary(var dict) = context else {
            return nil
        }

        switch parsed.parameters.count {
        case 1:
            let body = try parsed.requireBody()
            let key = parsed.parameters[0].string ?? ""
            let serializer = Serializer(ast: body, renderer: renderer, context: context)
            let rendered = try serializer.serialize()
            guard let string = String(data: rendered, encoding: .utf8) else {
                throw "could not convert data to string"
            }
            dict[key] = .string(string)
        case 2:
            let key = parsed.parameters[0].string ?? ""
            dict[key] = parsed.parameters[1]
        default:
            try parsed.requireParameterCount(2)
        }

        context = .dictionary(dict)
        return .string("")
    }
}
