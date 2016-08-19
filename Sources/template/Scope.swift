final class Scope {

    let workingDirectory: String = "./"

    internal(set) var queue: [FuzzyAccessible] = []

    init(_ any: Any) {
        self.queue.append(["self": any])
    }

    init(_ fuzzy: FuzzyAccessible) {
        self.queue.append(fuzzy)
    }

    func get(key: String) -> Any? {
        return queue.lazy.reversed().flatMap { $0.get(key: key) } .first
    }

    func get(path: String) -> Any? {
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

    func push(_ fuzzy: FuzzyAccessible) {
        queue.append(fuzzy)
    }

    @discardableResult
    func pop() -> FuzzyAccessible? {
        guard !queue.isEmpty else { return nil }
        return queue.removeLast()
    }
}
