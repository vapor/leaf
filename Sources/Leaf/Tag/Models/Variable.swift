public final class Variable: Tag {
    public enum Error: LeafError {
        case expectedOneArgument
    }

    public let name = "" // empty name, ie: @(variable)

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Node? {
        // temporary escaping mechanism. 
        // ALL tags are interpreted, use `#()` to have an empty `#` rendered
        if arguments.isEmpty { return .string([TOKEN].string) }
        guard arguments.count == 1 else { throw Error.expectedOneArgument }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return .string(value)
        case let .variable(path: _, value: value):
            return value
        }
    }
}
