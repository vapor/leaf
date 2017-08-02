import Bits

public protocol Tag {
    func render(
        parsed: ParsedTag,
        context: inout Data,
        renderer: Renderer
    ) throws -> Data?
}

// MARK: Global

<<<<<<< HEAD
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

=======
public var defaultTags: [String: Tag] = [
    "": Print(),
    "ifElse": IfElse(),
    "var": Var(),
    "embed": Embed(),
    "loop": Loop(),
    "comment": Comment()
]
>>>>>>> 81028ad840e134b10634292d06e789edb0c9782a
