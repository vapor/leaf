import Async

public final class Uppercase: TagRenderer {
    public init() {}
    public func render(parsed: TagContext, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.uppercased() ?? ""
        return Future(.string(string))
    }
}
