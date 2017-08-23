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
                try serializer.serialize().then { rendered in
                    guard let string = String(data: rendered, encoding: .utf8) else {
                        promise.complete("could not do string" as Error)
                        return
                    }
                    dict[key] = .string(string)
                    promise.complete(.dictionary(dict))
                }
            case 2:
                let key = parsed.parameters[0].string ?? ""
                dict[key] = parsed.parameters[1]
                promise.complete(.dictionary(dict))
            default:
                try parsed.requireParameterCount(2)
                promise.complete(.string(""))
            }
        } else {
            promise.complete(nil)
        }

        return promise.future
    }
}
