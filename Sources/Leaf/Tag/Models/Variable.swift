public final class Variable: Tag {
    public let name = "" // empty name, ie: @(variable)

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        // temporary escaping mechanism. 
        // ALL tags are interpreted, use `#()` to have an empty `#` rendered
        if arguments.isEmpty { return [TOKEN].string }
        guard arguments.count == 1 else { throw "invalid var argument" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }
}
