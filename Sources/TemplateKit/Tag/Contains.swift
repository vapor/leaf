import Async

public final class Contains: TagRenderer {
    public init() {}
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
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
