import Async

//public final class IfElse: TagRenderer {
//    public init() {}
//
//    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
//        try parsed.requireParameterCount(1)
//        let body = try parsed.requireBody()
//        let expr = parsed.parameters[0]
//
//        let promise = Promise(TemplateData.self)
//        if expr.bool == true || (expr.bool == nil && !expr.isNull) {
//            let serializer = LeafSerializer(
//                ast: body,
//                renderer: renderer,
//                context: context,
//                on: parsed.eventLoop
//            )
//            serializer.serialize().do { bytes in
//                promise.complete(.data(bytes))
//            }.catch { error in
//                promise.fail(error)
//            }
//        } else {
//            promise.complete(.null)
//        }
//
//        return promise.future
//    }
//}

