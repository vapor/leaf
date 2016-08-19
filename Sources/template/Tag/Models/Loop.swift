import Core

final class Loop: Tag {
    let name = "loop"

    func run(
        stem: Stem,
        filler: Scope,
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

    func render(
        stem: Stem,
        filler: Scope,
        value: Any?,
        template: Leaf) throws -> Bytes {
        guard let array = value as? [Any] else { fatalError() }

        return try array
            .map { item -> Bytes in
                if let i = item as? FuzzyAccessible {
                    filler.push(i)
                } else {
                    filler.push(["self": item])
                }

                let rendered = try stem.render(template, with: filler)

                filler.pop()

                return rendered
            }
            .flatMap { $0 + [.newLine] }
    }
}
