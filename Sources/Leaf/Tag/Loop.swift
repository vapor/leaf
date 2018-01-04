import Async
import Foundation

public final class Loop: LeafTag {
    public init() {}
    public func render(parsed: ParsedTag, context: LeafContext, renderer: LeafRenderer) throws -> Future<LeafData?> {
        let promise = Promise(LeafData?.self)

        let body = try parsed.requireBody()
        try parsed.requireParameterCount(2)
        let key = parsed.parameters[1].string ?? ""
        
        if case .dictionary(var dict) = context.data {
            var results: [Future<Data>] = []
            
            // store the previous values of loop and key
            // so we can restore them once the loop is finished
            let prevLoop = dict["loop"]
            let prevKey = dict[key]
            
            func render(_ render: Render) {
                let loop = LeafData.dictionary([
                    "index": .int(render.index),
                    "isFirst": .bool(render.isFirst),
                    "isLast": .bool(render.isLast)
                ])
                
                dict["loop"] = loop
                dict[key] = render.data
                context.data = .dictionary(dict)
                
                let serializer = Serializer(
                    ast: body,
                    renderer: renderer,
                    context: context,
                    on: parsed.eventLoop
                )
                
                serializer.serialize().do { bytes in
                    render.promise.complete(bytes)
                }.catch { error in
                    render.promise.fail(error)
                }
            }
            
            func applyResults() {
                results.flatten().do { datas in
                    let data = Data(datas.joined())
                    dict["loop"] = prevLoop
                    dict[key] = prevKey
                    context.data = .dictionary(dict)
                    promise.complete(.data(data))
                }.catch { error in
                    promise.fail(error)
                }
            }
            
            let parameter = parsed.parameters[0]

            if let array = parameter.array {
                for (i, item) in array.enumerated() {
                    let context = Render(index: i, data: item)
                    render(context)
                    
                    results.append(context.promise.future)
                }
                
                applyResults()
            } else if case .stream(let stream) = parameter {
                var nextRender: Render?
                
                var index = 0
                
<<<<<<< HEAD
                var upstream: ConnectionContext?
                
                stream.drain { _upstream in
                    upstream = _upstream
                }.output { data in
=======
                stream.map(to: LeafData.self) { encodable in
                    return try LeafEncoder().encode(encodable)
                }.drain { _ in }
                .output { data in
>>>>>>> c74e1917551b9ffba8d09220bf08b7fd43a398b7
                    defer { index += 1 }
                    
                    if let nextRender = nextRender {
                        render(nextRender)
                    }
                    
                    let context = Render(index: index, data: data)
                    results.append(context.promise.future)
                    nextRender = context
                    
                    upstream?.request()
                }.catch { error in
                    promise.fail(error)
                    upstream?.cancel()
                }.finally {
                    if var nextRender = nextRender {
                        nextRender.isLast = true
                        render(nextRender)
                    }
                    
                    applyResults()
                }
                
                upstream?.request()
            }
        } else {
            promise.complete(nil)
        }

        return promise.future
    }
}

fileprivate struct Render {
    var index: Int
    var data: LeafData
    var isLast = false
    let promise = Promise<Data>()
    
    var isFirst: Bool {
        return index == 0
    }
    
    init(index: Int, data: LeafData) {
        self.index = index
        self.data = data
    }
}
