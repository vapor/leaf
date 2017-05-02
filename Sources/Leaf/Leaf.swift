import Core
import libc

/**
    🍃
 
    Create from Stems
*/
public final class Leaf {
    /**
        The raw string used to render this leaf.
    */
    public let raw: String

    /**
        The compiled components generated from the raw string
    */
    // public let components: [Component]
    public let components: List<Component>

    public let size: Int

    internal init(raw: String, components: [Component]) {
        self.raw = raw
        let components = List(components)
        self.components = components

        /// I can't find a way to dynamically infer the size of a given component, so we will use roughly
        /// double its raw representation
        let rawSize = raw.utf8.count
        self.size = rawSize * 2
    }
}

extension Leaf: Cacheable {
    public func cacheSize() -> Size {
        return size
    }
}

extension Leaf: CustomStringConvertible {
    public var description: String {
        let components = self.components.map { $0.description } .joined(separator: "\n")
        return "Leaf: \n" + components
    }
}

extension Leaf: Equatable {}
public func == (lhs: Leaf, rhs: Leaf) -> Bool {
    for (l, r) in zip(lhs.components, rhs.components) where l != r {
        return false
    }

    return lhs.raw == rhs.raw
}
