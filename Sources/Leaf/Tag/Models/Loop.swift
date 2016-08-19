public final class Loop: Tag {
    public let name = "loop"

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.count == 2 else {
            throw "loop requires two arguments, var w/ array, and constant w/ sub name"
        }

        switch (arguments[0], arguments[1]) {
        case let (.variable(key: _, value: value?), .constant(value: innername)):
            let array = value as? [Any] ?? [value]
            return array.map { [innername: $0] }
        // return true
        default:
            return nil
            // return false
        }
    }

    public func render(
        stem: Stem,
        context: Context,
        value: Any?,
        leaf: Leaf) throws -> Bytes {
        guard let array = value as? [Any] else { fatalError() }
        return try array
            .map { item -> Bytes in
                if let i = item as? FuzzyAccessible {
                    context.push(i)
                } else {
                    context.push(["self": item])
                }
                defer { context.pop() }

                return try stem.render(leaf, with: context)
            }
            .flatMap { $0 + [.newLine] }
    }
}
