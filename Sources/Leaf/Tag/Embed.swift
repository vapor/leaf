import Core

public final class Embed: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Future<Context?> {
        try parsed.requireParameterCount(1)
        let name = parsed.parameters[0].string ?? ""
        let copy = context

        let promise = Promise(Context?.self)

        renderer.render(path: name, context: copy, on: parsed.queue).then(on: parsed.queue) { data in
            if let string = String(data: data, encoding: .utf8) {
                promise.complete(.string(string))
            } else {
                promise.fail("could not parse string")
            }
        }

        return promise.future
    }
}


