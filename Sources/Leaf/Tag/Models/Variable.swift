public final class Variable: Tag {
    public enum Error: LeafError {
        case expectedOneArgument
    }

    public let name = "" // empty name, ie: *(variable)

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Node? {
        // temporary escaping mechanism. 
        // ALL tags are interpreted, use `*()` to have an empty `*` rendered
        if arguments.isEmpty { return .string([TOKEN].makeString()) }
        guard arguments.count == 1 else { throw Error.expectedOneArgument }
        return arguments[0].value(with: stem, in: context)
    }
}
