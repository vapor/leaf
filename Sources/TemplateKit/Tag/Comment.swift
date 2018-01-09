import Async

public final class Comment: TemplateTag {
    public init() {}
    
    public func render(parsed: TagSyntax, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        return Future(.string(""))
    }
}
