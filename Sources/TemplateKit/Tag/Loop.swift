//import Async
//import Foundation
//
//public final class Loop: TagRenderer {
//    public init() {}
//    public func render(tag parsed: TagContext) throws -> Future<TemplateData> {
//        let promise = Promise(TemplateData.self)
//
//        let body = try parsed.requireBody()
//        try parsed.requireParameterCount(2)
//        let key = parsed.parameters[1].string ?? ""
//        
//        if case .dictionary(var dict) = parsed.context.data {
//            var results: [Future<Data>] = []
//            
//            // store the previous values of loop and key
//            // so we can restore them once the loop is finished
//            let prevLoop = dict["loop"]
//            let prevKey = dict[key]
//            
//            func render(_ render: Render) {
//                let loop = TemplateData.dictionary([
//                    "index": .int(render.index),
//                    "isFirst": .bool(render.isFirst),
//                    "isLast": .bool(render.isLast)
//                ])
//                
//                dict["loop"] = loop
//                dict[key] = render.data
//                context.data = .dictionary(dict)
//                
//                let serializer = LeafSerializer(
//                    ast: body,
//                    renderer: renderer,
//                    context: context,
//                    on: parsed.eventLoop
//                )
//                
//                serializer.serialize().do { bytes in
//                    render.promise.complete(bytes)
//                }.catch { error in
//                    render.promise.fail(error)
//                }
//            }
//            
//            func applyResults() {
//                results.flatten().do { datas in
//                    let data = Data(datas.joined())
//                    dict["loop"] = prevLoop
//                    dict[key] = prevKey
//                    context.data = .dictionary(dict)
//                    promise.complete(.data(data))
//                }.catch { error in
//                    promise.fail(error)
//                }
//            }
//            
//            let parameter = parsed.parameters[0]
//
//            if let array = parameter.array {
//                for (i, item) in array.enumerated() {
//                    let context = Render(index: i, data: item)
//                    render(context)
//                    
//                    results.append(context.promise.future)
//                }
//                
//                applyResults()
//            } else if case .stream(let stream) = parameter {
//                var nextRender: Render?
//                
//                var index = 0
//            
//                var upstream: ConnectionContext?
//                
//                stream.drain { _upstream in
//                    upstream = _upstream
//                }.output { data in
//                    defer { index += 1 }
//                    
//                    if let nextRender = nextRender {
//                        render(nextRender)
//                    }
//                    
//                    let context = Render(index: index, data: data)
//                    results.append(context.promise.future)
//                    nextRender = context
//                    
//                    upstream?.request()
//                }.catch { error in
//                    promise.fail(error)
//                    upstream?.cancel()
//                }.finally {
//                    if var nextRender = nextRender {
//                        nextRender.isLast = true
//                        render(nextRender)
//                    }
//                    
//                    applyResults()
//                }
//                
//                upstream?.request()
//            }
//        } else {
//            promise.complete(.null)
//        }
//
//        return promise.future
//    }
//}
//
//fileprivate struct Render {
//    var index: Int
//    var data: TemplateData
//    var isLast = false
//    let promise = Promise<Data>()
//    
//    var isFirst: Bool {
//        return index == 0
//    }
//    
//    init(index: Int, data: TemplateData) {
//        self.index = index
//        self.data = data
//    }
//}

