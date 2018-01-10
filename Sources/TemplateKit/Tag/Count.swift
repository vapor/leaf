import Async

public final class Count: TagRenderer {
    init() {}
    
    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
        let promise = Promise(TemplateData.self)
        try parsed.requireParameterCount(1)
        
        switch parsed.parameters[0] {
        case .dictionary(let dict):
            promise.complete(.int(dict.values.count))
        case .array(let arr):
            promise.complete(.int(arr.count))
        default:
            promise.complete(.null)
        }

        return promise.future
    }
}

