import Foundation

public protocol FuzzyAccessible {
    func get(key: String) -> Any?
}

extension FuzzyAccessible {
    public func get(path: String) -> Any? {
        let components = path.characters
            .split(separator: ".", omittingEmptySubsequences: true)
            .map { String($0) }
        print("Components: \(components)")
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
        guard let k = key as? Key else { return nil }
        if let ob = self[k] { return ob }

        switch key {
        case "self":
            return self
        case "keys":
            return self.keys
        case "values":
            return self.values
        case "count":
            return self.count
        default:
            return nil
        }
    }
}

extension NSDictionary: FuzzyAccessible {
    public func get(key: String) -> Any? {
        let ns = NSString(string: key)
        if let ob = self.object(forKey: ns) { return ob }

        switch key {
        case "self":
            return self
        case "keys":
            return self.allKeys
        case "values":
            return self.allValues
        case "count":
            return self.count
        default:
            return nil
        }
    }
}

extension Array: FuzzyAccessible {
    public func get(key: String) -> Any? {
        if let idx = Int(key), idx < count { return self[idx] }

        switch key {
        case "self":
            return self
        case "first":
            return self.first
        case "last":
            return self.last
        case "count":
            return self.count
        default:
            return nil
        }
    }
}

extension NSArray: FuzzyAccessible {
    public func get(key: String) -> Any? {
        if let idx = Int(key), idx < count { return self[idx] }

        switch key {
        case "self":
            return self
        case "first":
            return self.firstObject
        case "last":
            return self.lastObject
        case "count":
            return self.count
        default:
            return nil
        }
    }
}
