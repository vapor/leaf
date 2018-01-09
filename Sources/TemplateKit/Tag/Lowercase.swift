import Async

public final class Lowercase: TemplateTag {
    public init() {}
    public func render(parsed: TagSyntax, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.lowercased() ?? ""
        return Future(.string(string))
    }
}
