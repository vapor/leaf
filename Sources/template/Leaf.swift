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
    public let components: [Component]

    internal init(raw: String) throws {
        self.raw = raw
        var buffer = Buffer(raw.bytes.trimmed(.whitespace).array)
        self.components = try buffer.components()
    }

    internal init(raw: String, components: [Component]) {
        self.raw = raw
        self.components = components
    }
}
