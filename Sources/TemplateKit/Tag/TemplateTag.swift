import Async
import Foundation

public protocol TemplateTag {
    func render(
        parsed: TagSyntax,
        context: TemplateContext,
        renderer: TemplateRenderer
    ) throws -> Future<TemplateData>
}

// MARK: Global

public var defaultTags: [String: TemplateTag] {
    return [
        "": Print(),
        "ifElse": IfElse(),
        "loop": Loop(),
        "comment": Comment(),
        "contains": Contains(),
        "lowercase": Lowercase(),
        "uppercase": Uppercase(),
        "capitalize": Capitalize(),
        "count": Count(),
        "set": Var(),
        "get": Raw(),
        "embed": Embed(),
        "date": DateFormat()
    ]
}
