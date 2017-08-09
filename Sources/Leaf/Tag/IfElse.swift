import Bits

public final class IfElse: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(1)
        let body = try parsed.requireBody()
        let expr = parsed.parameters[0]

        if expr.bool != false {
            let bytes = try renderer.render(body, context: context)
            return .string(bytes.makeString())
        } else {
            return nil
        }
    }
}
