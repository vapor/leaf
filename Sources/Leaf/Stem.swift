public final class Stem {
    public let workingDirectory: String
    public var cache: [String: Leaf]?
    public fileprivate(set) var tags: [String: Tag] = defaultTags

    public init(workingDirectory: String, cache: [String: Leaf]? = [:]) {
        self.workingDirectory = workingDirectory.finished(with: "/")
        self.cache = cache
    }
}

extension Stem {
    public func cache(_ leaf: Leaf, named name: String) {
        cache?[name] = leaf
    }
}

extension Stem {
    public func register(_ tag: Tag) {
        tags[tag.name] = tag
    }

    public func remove(_ tag: Tag) {
        removeTag(named: tag.name)
    }

    public func removeTag(named name: String) {
        tags[name] = nil
    }
}
