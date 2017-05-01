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

        let rawSize = raw.utf8.count
        // TODO: Verify http://stackoverflow.com/a/40334422/2611971
        let listSize = malloc_size(Unmanaged.passRetained(components).toOpaque())
        self.size = rawSize + listSize + MemoryLayout<Int>.size
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
