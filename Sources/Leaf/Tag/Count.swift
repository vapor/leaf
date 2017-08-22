public final class Count: Leaf.Tag {
    init() {}
    
    public func render(parsed: ParsedTag, context: inout Context, renderer: Renderer) throws -> Context? {
        try parsed.requireParameterCount(1)

        switch parsed.parameters[0] {
        case .dictionary(let dict):
            return .int(dict.values.count)
        case .array(let arr):
            return .int(arr.count)
        default:
            return .null
        }
    }
}

