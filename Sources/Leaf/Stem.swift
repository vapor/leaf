import Core

private let _bytes = 1
private let _kilobytes = _bytes * 1000
private let _megabytes = _kilobytes * 1000
private let _gigabytes = _megabytes * 1000

extension Int {
    var bytes: Int { return self }
    var kilobytes: Int { return self * _kilobytes }
    var megabytes: Int { return self * _megabytes }
    var gigabytes: Int { return self * _gigabytes }
}

public final class Stem {
    public let file: FileProtocol
    public var cache: Cache<Leaf>?
    public fileprivate(set) var tags: [String: Tag] = defaultTags

    public init(_ file: FileProtocol, cache: Cache<Leaf>? = .init(maxSize: 500.megabytes)) {
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

public typealias Size = Int

public protocol Cacheable {
    func cacheSize() ->  Size
}

public protocol CacheProtocol {
    associatedtype Wrapped: Cacheable
    init(maxSize: Size)
    subscript(key: String) -> Wrapped? { get set }
}

public final class Cache<Wrapped: Cacheable>: CacheProtocol {
    public let maxSize: Size

    private var ordered: OrderedDictionary<String, Wrapped> = .init()

    public init(maxSize: Size) {
        self.maxSize = maxSize
    }

    public subscript(key: String) -> Wrapped? {
        get {
            return ordered[key]
        }
        set {
            ordered[key] = newValue
            vent()
        }
    }

    private func vent() {
        let total = totalSize()
        guard total <= maxSize else { return }

        var dropTotal = total - maxSize
        while dropTotal > 0 {
            let next = dropOldest()
            guard let size = next?.cacheSize() else { break }
            dropTotal -= size
        }
    }

    private func totalSize() -> Size {
        return ordered.unorderedItems.map { $0.cacheSize() } .reduce(0, +)
    }

    func dropOldest() -> Wrapped? {
        guard let oldest = ordered.oldest else { return nil }
        ordered[oldest.key] = nil
        return oldest.value
    }
}

fileprivate struct OrderedDictionary<Key: Hashable, Value> {
    fileprivate var oldest: (key: Key, value: Value)? {
        guard let key = list.first, let value = backing[key] else { return nil }
        return (key, value)
    }

    fileprivate var newest: (key: Key, value: Value)? {
        guard let key = list.last, let value = backing[key] else { return nil }
        return (key, value)
    }

    fileprivate var items: [Value] {
        return list.flatMap { backing[$0] }
    }

    // theoretically slightly faster
    fileprivate var unorderedItems: LazyMapCollection<Dictionary<Key, Value>, Value> {
        return backing.values
    }

    private var list: [Key] = []
    private var backing: [Key: Value] = [:]

    fileprivate subscript(key: Key) -> Value? {
        mutating get {
            if let existing = backing[key] {
                return existing
            } else {
                remove(key)
                return nil
            }
        }
        set {
            if let newValue = newValue {
                // overwrite anything that might exist
                remove(key)
                backing[key] = newValue
                list.append(key)

            } else {
                backing[key] = nil
                remove(key)
            }
        }
    }

    fileprivate subscript(idx: Int) -> (key: Key, value: Value)? {
        guard idx < list.count, idx >= 0 else { return nil }
        let key = list[idx]
        guard let value = backing[key] else { return nil }
        return (key, value)
    }

    fileprivate mutating func remove(_ key: Key) {
        if let idx = list.index(of: key) {
            list.remove(at: idx)
        }
    }
}
