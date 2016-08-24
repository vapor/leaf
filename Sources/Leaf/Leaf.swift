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

    internal init(raw: String) throws {
        self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self.components = List(try buffer.components())
    }

    internal init(raw: String, components: [Component]) {
        self.raw = raw
        self.components = List(components)
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
