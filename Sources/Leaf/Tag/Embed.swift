import Core

public final class Embed: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Future<Context?> {
        try parsed.requireParameterCount(1)
        let name = parsed.parameters[0].string ?? ""
        let copy = context

        let promise = Promise(Context?.self)

        renderer.render(path: name, context: copy).then { data in
            guard let string = String(data: data, encoding: .utf8) else {
                promise.complete("could not parse string" as Error)
                return
            }
            promise.complete(.string(string))
        }

        return promise.future
    }
}


