import Foundation

public protocol Tag {
    func render(
        parsed: ParsedTag,
        context: inout Context,
        renderer: Renderer
    ) throws -> Context?
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
        "lowercase": Lowercase(),
        "count": Count()
    ]
}
