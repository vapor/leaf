import Foundation

public protocol FuzzyAccessible {
    func get(key: String) -> Any?
}

extension FuzzyAccessible {
    public func get(path: String) -> Any? {
        let components = path.components(separatedBy: ".")
        return get(path: components)
    }

    public func get(path: [String]) -> Any? {
        let first: Optional<Any> = self
        return path.reduce(first) { next, index in
            guard let next = next as? FuzzyAccessible else { return nil }
            return next.get(key: index)
        }
    }
}

extension Dictionary: FuzzyAccessible {
    public func get(key: String) -> Any? {
        // TODO: Throw if invalid key?
        guard let key = key as? Key else { return nil }
        let value: Value? = self[key]
        return value
    }
}

extension NSDictionary: FuzzyAccessible {
    public func get(key: String) -> Any? {
        let ns = NSString(string: key)
        return self.object(forKey: ns)
    }
}

extension Array: FuzzyAccessible {
    public func get(key: String) -> Any? {
        guard let idx = Int(key), idx < count else { return nil }
        return self[idx]
    }
}

extension NSArray: FuzzyAccessible {
    public func get(key: String) -> Any? {
        guard let idx = Int(key), idx < count else { return nil }
        return self.object(at: idx)
    }
}
