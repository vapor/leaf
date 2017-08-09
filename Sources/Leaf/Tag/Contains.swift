public final class Contains: Leaf.Tag {
    public func render(parsed: ParsedTag, context: inout Data, renderer: Renderer) throws -> Data? {
        try parsed.requireParameterCount(2)

        guard let array = parsed.parameters[0].array else {
            return .bool(false)
        }
        let compare = parsed.parameters[1]

        return .bool(array.contains(compare))
    }
}
