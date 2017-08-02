import Bits

public final class IfElse: Tag {
    public init() {}

    public func render(
        parameters: [Data?],
        context: inout Data,
        body: [Syntax]?,
        renderer: Renderer
    ) throws -> Data? {
        let expr = try requireParameter(0, from: parameters)
        let body = try requireBody(body)

        if expr?.bool != false {
            let bytes = try renderer.render(body, context: context)
            return .string(bytes.makeString())
        } else {
            return nil
        }
    }
}
