import Core

public final class IfElse: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Future<Context?> {
        try parsed.requireParameterCount(1)
        let body = try parsed.requireBody()
        let expr = parsed.parameters[0]

        let promise = Promise(Context?.self)
        if expr.bool != false {
            let serializer = Serializer(ast: body, renderer: renderer, context: context)
            try serializer.serialize().then { bytes in
                guard let string = String(data: bytes, encoding: .utf8) else {
                    promise.complete("could not convert data to string" as Error)
                    return
                }
                promise.complete(.string(string))
            }
        } else {
            promise.complete(nil)
        }

        return promise.future
    }
}
