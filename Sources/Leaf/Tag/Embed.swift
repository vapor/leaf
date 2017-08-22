public final class Embed: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Context? {
        try parsed.requireParameterCount(1)
        let name = parsed.parameters[0].string ?? ""
        let copy = context

        return .future({ callback in
            renderer.render(path: name, context: copy) { data in
                // fixme: handle string not decoded error
                let string = String(data: data, encoding: .utf8) ?? ""
                callback(.string(string))
            }
        })
    }
}


