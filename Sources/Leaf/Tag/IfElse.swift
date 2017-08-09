import Bits

public final class IfElse: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(1)
        let body = try parsed.requireBody()
        let expr = parsed.parameters[0]

        if expr.bool != false {
            let serializer = Serializer(ast: body, renderer: renderer, context: context)
            let bytes = try serializer.serialize()
            return .string(bytes.makeString())
        } else {
            return nil
        }
    }
}
