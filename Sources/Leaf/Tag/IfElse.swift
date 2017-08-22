public final class IfElse: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Context? {
        try parsed.requireParameterCount(1)
        let body = try parsed.requireBody()
        let expr = parsed.parameters[0]

        if expr.bool != false {
            let serializer = Serializer(ast: body, renderer: renderer, context: context)
            let bytes = try serializer.serialize()
            guard let string = String(data: bytes, encoding: .utf8) else {
                throw "could not convert data to string"
            }
            return .string(string)
        } else {
            return nil
        }
    }
}
