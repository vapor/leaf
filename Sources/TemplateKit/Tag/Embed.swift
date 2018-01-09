import Async

public final class Embed: TemplateTag {
    public init() {}
    public func render(parsed: TagSyntax, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        try parsed.requireParameterCount(1)
        let name = parsed.parameters[0].string ?? ""
        let copy = context

        let promise = Promise(TemplateData.self)

        renderer.render(path: name, context: copy).do { data in
            promise.complete(.data(data))
        }.catch { error in
            promise.fail(error)
        }

        return promise.future
    }
}


