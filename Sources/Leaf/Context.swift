/**
    The associated context used in rendering
*/
public final class Context {
    public internal(set) var queue: [FuzzyAccessible] = []

    public init(_ any: Any) {
        self.queue.append(["self": any])
    }

    public init(_ fuzzy: FuzzyAccessible) {
        self.queue.append(fuzzy)
    }

    public func get(key: String) -> Any? {
        return queue.lazy.reversed().flatMap { $0.get(key: key) } .first
    }

    public func get(path: String) -> Any? {
        let components = path.components(separatedBy: ".")
        return queue.lazy
            .reversed() // bottom up
            .flatMap { next in next.get(path: components) }
            .first
    }

    public func get(path: [String]) -> Any? {
        let first: Optional<Any> = self
        return path.reduce(first) { next, index in
            guard let next = next as? FuzzyAccessible else { return nil }
            return next.get(key: index)
        }
    }

    public func push(_ fuzzy: FuzzyAccessible) {
        queue.append(fuzzy)
    }

    @discardableResult
    public func pop() -> FuzzyAccessible? {
        guard !queue.isEmpty else { return nil }
        return queue.removeLast()
    }
}


extension Context {
    internal func renderedSelf() throws -> Bytes? {
        guard let value = get(path: "self") else { return nil }
        guard let renderable = value as? Renderable else { return "\(value)".bytes }
        return try renderable.rendered()
    }
}
