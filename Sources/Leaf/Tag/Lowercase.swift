public final class Lowercase: Leaf.Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.lowercased() ?? ""
        return .string(string)
    }
}
