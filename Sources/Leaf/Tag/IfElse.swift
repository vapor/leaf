import Bits

public final class IfElse: Tag {
    public init() {}

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

        if expr.bool != false {
            let bytes = try renderer.render(body, context: context)
            return .string(bytes.makeString())
        } else {
            return nil
        }
    }
}
