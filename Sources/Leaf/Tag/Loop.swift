import Core

public final class Loop: Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Future<Context?> {
        let promise = Promise(Context?.self)

        if case .dictionary(var dict) = context {
            let body = try parsed.requireBody()
            try parsed.requireParameterCount(2)
            let array = parsed.parameters[0].array ?? []
            let key = parsed.parameters[1].string ?? ""

            var results: [Future<String>] = []

            for (i, item) in array.enumerated() {
                let isLast = i == array.count - 1
                let loop = Context.dictionary([
                    "index": .int(i),
                    "isFirst": .bool(i == 0),
                    "isLast": .bool(isLast)
                    ])
                dict["loop"] = loop
                dict[key] = item
                let temp = Context.dictionary(dict)
                let serializer = Serializer(ast: body, renderer: renderer, context: temp)

                let subpromise = Promise(String.self)
                try serializer.serialize(on: parsed.queue).then(on: parsed.queue) { bytes in
                    if let sub = String(data: bytes, encoding: .utf8) {
                        subpromise.complete(sub)
                    } else {
                        subpromise.fail("could not convert data to string")
                        return
                    }
                }
                results.append(subpromise.future)
            }

            results.flatten(on: parsed.queue).then(on: parsed.queue) { strings in
                promise.complete(.string(strings.joined()))
            }
        } else {
            promise.complete(nil)
        }

        return promise.future
    }
}
