import Async

/// A reference wrapper around template data.
public final class TemplateContext {
    /// The wrapped data
    public var data: TemplateData

    /// Create a new LeafContext
    public init(data: TemplateData) {
        self.data = data
    }
}

extension TemplateContext {
    // Fetches data from that context at the supplied coding key.
    public func fetch(at path: [CodingKey]) -> Future<TemplateData> {
        var promise = Promise(TemplateData.self)

        var current = data
        var iterator = path.makeIterator()

        func handle(_ path: CodingKey) {
            switch current {
            case .array(let arr):
                if let index = path.intValue, arr.count > index {
                    let value = arr[index]
                    current = value
                    if let next = iterator.next() {
                        handle(next)
                    } else {
                        promise.complete(current)
                    }
                } else {
                    promise.complete(.null)
                }
            case .dictionary(let dict):
                if let value = dict[ path.stringValue] {
                    current = value
                    if let next = iterator.next() {
                        handle(next)
                    } else {
                        promise.complete(current)
                    }
                } else {
                    promise.complete(.null)
                }
            case .future(let fut):
                fut.do { value in
                    current = value
                    handle(path)
                    }.catch { error in
                        promise.fail(error)
                }
            default:
                promise.complete(.null)
            }
        }

        if let first = iterator.next() {
            handle(first)
        } else {
            promise.complete(current)
        }

        return promise.future
    }
}
