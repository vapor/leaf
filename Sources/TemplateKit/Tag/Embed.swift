import Async

//public final class Embed: TagRenderer {
//    public init() {}
//    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
//        try parsed.requireParameterCount(1)
//        let name = parsed.parameters[0].string ?? ""
//        let copy = parsed.context
//
//        let promise = Promise(TemplateData.self)
//
//        renderer.render(path: name, context: copy).do { data in
//            promise.complete(.data(data))
//        }.catch { error in
//            promise.fail(error)
//        }
//
//        return promise.future
//    }
//}


