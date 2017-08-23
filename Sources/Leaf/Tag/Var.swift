import Core

public final class Var: Tag {
    public init() {}

    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Future<Context?> {
        let promise = Promise(Context?.self)

        if case .dictionary(var dict) = context {
            switch parsed.parameters.count {
            case 1:
                let body = try parsed.requireBody()
                let key = parsed.parameters[0].string ?? ""

                let serializer = Serializer(ast: body, renderer: renderer, context: context)

                // FIXME: any way to make this not sync?
                let rendered = try serializer.serialize(
                    on: parsed.queue
                ).sync()
                if let string = String(data: rendered, encoding: .utf8) {
                    dict[key] = .string(string)
                    context = .dictionary(dict)
                    promise.complete(nil)
                } else {
                    promise.fail("could not do string")
                }
            case 2:
                let key = parsed.parameters[0].string ?? ""
                dict[key] = parsed.parameters[1]
                context = .dictionary(dict)
                promise.complete(nil)
            default:
                try parsed.requireParameterCount(2)
            }
        } else {
            promise.complete(nil)
        }

        return promise.future
    }
}
