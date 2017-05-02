public final class Uppercased: Tag {
    public enum Error: LeafError {
        case expectedOneArgument
        case expectedStringArgument
    }

    public let name = "uppercased"

    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedOneArgument }
        // Ok for nil value
        guard let value = arguments.first else { return nil }
        guard let string = value.string else { throw Error.expectedStringArgument }
        return .string(string.uppercased())
    }
}
