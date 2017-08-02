import Bits

public protocol Tag {
    func render(
        parsed: ParsedTag,
        context: inout Data,
        renderer: Renderer
    ) throws -> Data?
}

// MARK: Global

public var defaultTags: [String: Tag] {
    return [
        "": Print(),
        "ifElse": IfElse(),
        "var": Var(),
        "embed": Embed(),
        "loop": Loop(),
        "comment": Comment(),
        "contains": Contains(),
        "lowercase": Lowercase()
    ]
}
