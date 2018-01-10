import Async

public final class Print: TagRenderer {
    public init() { }

    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        try parsed.requireNoBody()
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string ?? ""
        return Future(.string(string.htmlEscaped()))
    }
}

