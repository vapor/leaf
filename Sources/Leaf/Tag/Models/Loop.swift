public final class Loop: Tag {
    public let name = "loop"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Node? {
        guard arguments.count == 2 else {
            throw "loop requires two arguments, var w/ array, and constant w/ sub name"
        }

        switch (arguments[0], arguments[1]) {
        case let (.variable(key: _, value: value?), .constant(value: innername)):
            let array = value.nodeArray ?? [value]
            return .array(array.map { [innername: $0] })
        default:
            return nil
        }
    }

    public func render(
        stem: Stem,
        context: Context,
        value: Node?,
        leaf: Leaf) throws -> Bytes {
        guard let array = value?.nodeArray else { fatalError() }
        return try array
            .map { item -> Bytes in
                if case .object(_) = item {
                    context.push(item)
                } else if case .array(_) = item {
                    context.push(item)
                } else {
                    context.push(["self": item])
                }
                defer { context.pop() }

                return try stem.render(leaf, with: context)
            }
            .flatMap { $0 + [.newLine] }
    }
}
