import Async
import Foundation

public protocol TagRenderer {
    func render(tag: TagContext) throws -> Future<TemplateData>
}

// MARK: Global

public var defaultTags: [String: TagRenderer] {
    return [
        "": Print(),
        // "ifElse": IfElse(),
        // "loop": Loop(),
        // "comment": Comment(),
        "contains": Contains(),
        "lowercase": Lowercase(),
        "uppercase": Uppercase(),
        "capitalize": Capitalize(),
        "count": Count(),
        "set": Var(),
        "get": Raw(),
        // "embed": Embed(),
        "date": DateFormat()
    ]
}
