import Async

public final class Contains: TemplateTag {
    public init() {}
  
    public func render(parsed: TagSyntax, context: TemplateContext, renderer: TemplateRenderer) throws -> Future<TemplateData> {
        let promise = Promise(TemplateData.self)

        try parsed.requireParameterCount(2)

        if let array = parsed.parameters[0].array {
            let compare = parsed.parameters[1]
            promise.complete(.bool(array.contains(compare)))
        } else {
            promise.complete(.bool(false))
        }

        return promise.future
    }
}
