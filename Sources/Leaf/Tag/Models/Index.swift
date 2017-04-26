public class Index: Tag {
    public let name = "index"

    public func run(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Node? {
        guard
            arguments.count == 2,
            let array = arguments[0].value(with: stem, in: context)?.array,
            let index = arguments[1].value(with: stem, in: context)?.int,
            index < array.count
            else { return nil }
        return array[index]
    }
}
