import Async

public final class Raw: TemplateTag {
    public init() { }

    public func render(parsed: TagSyntax, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        try parsed.requireNoBody()
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string ?? ""
        return Future(.string(string))
    }
}


