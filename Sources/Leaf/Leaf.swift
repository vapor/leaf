/**
    🍃
 
    Create from Stems
*/
public final class Leaf {
    /**
        The raw string used to render this leaf.
    */
    // public let raw: String

    /**
        The compiled components generated from the raw string
    */
    // public let _components: [Component]
    public let _components: List<Component>

    internal init(raw: String) throws {
        // self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self._components = List(try buffer.components())
    }

    internal init(raw: String, components: [Component]) {
        // self.raw = raw
        self._components = List(components)
    }
}

extension Leaf: CustomStringConvertible {
    public var description: String {
        let components = self._components.map { $0.description } .joined(separator: ", ")
        return "Leaf: " + components
    }
}
/*
extension Leaf: Equatable {}
public func == (lhs: Leaf, rhs: Leaf) -> Bool {
    return lhs._components == rhs._components
    // return lhs.raw == rhs.raw
}
*/
