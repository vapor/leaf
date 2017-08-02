import Bits

public final class IfElse: Tag {
    public init() {}

<<<<<<< HEAD
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(1)
        let body = try parsed.requireBody()
        let expr = parsed.parameters[0]
=======
    public func render(
        parameters: [Data],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        guard parameters.count == 1 else {
            throw TagError.missingParameter(0)
        }
        let expr = parameters[0]
        let body = try requireBody(body)
>>>>>>> 81028ad840e134b10634292d06e789edb0c9782a

        if expr.bool != false {
            let bytes = try renderer.render(body, context: context)
            return .string(bytes.makeString())
        } else {
            return nil
        }
    }
}
