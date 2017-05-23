import Core
import Bits

public final class Stem {
    public let file: FileProtocol
    public var cache: SystemCache<Leaf>?
    public fileprivate(set) var tags: [String: Tag] = defaultTags
    public fileprivate(set) var expressions: [Expression] = defaultExpressions

    public init(_ file: FileProtocol, cache: SystemCache<Leaf>? = .init(maxSize: 500.megabytes)) {
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

extension Stem {
    public func expression(matching arguments: [String]) -> Expression? {
        return expressions.first { $0.matches(arguments) }
    }
}
