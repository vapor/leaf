public final class Uppercased: Tag {
    public enum Error: LeafError {
        case expectedOneArgument
        case expectedStringArgument
    }

    public let name = "uppercased"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedOneArgument }
        // Ok for nil value
        guard let value = arguments.first?.value(with: stem, in: context) else { return nil }
        guard let string = value.string else { throw Error.expectedStringArgument }
        return .string(string.uppercased())
    }
}
