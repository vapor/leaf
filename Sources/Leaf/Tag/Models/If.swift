public final class If: Tag {
    public enum Error: LeafError {
        case expectedSingleArgument(have: [Argument])
    }

    public let name = "if"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedSingleArgument(have: arguments) }
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Node?) -> Bool {
        guard let value = arguments.first?.value else { return false }
        // Existence of bool, evaluate bool. Otherwise, not-nil returns true.
        guard let bool = value.bool else { return true }
        return bool
    }
}
