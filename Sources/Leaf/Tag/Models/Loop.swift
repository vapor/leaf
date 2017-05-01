public final class Loop: Tag {
    public enum Error: LeafError {
        case expectedTwoArguments(have: [Argument])
        case expectedVariable(have: Argument)
        case expectedConstant(have: Argument)
    }

    public let name = "loop"

    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList
    ) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments.list) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: variable)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: constant)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()

        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        return .array(array.map { [innername: $0] })
    }

    public func render(
        stem: Stem,
        context: Context,
        value: Node?,
        leaf: Leaf
    ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
}
