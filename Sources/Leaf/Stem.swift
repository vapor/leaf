import Core

public final class Stem {
    public let file: FileProtocol
    public var cache: [String: Leaf]?
    public fileprivate(set) var tags: [String: Tag] = defaultTags

    public init(_ file: FileProtocol, cache: [String: Leaf]? = [:]) {
        self.file = file
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
