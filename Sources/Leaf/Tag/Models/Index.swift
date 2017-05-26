public class Index: Tag {
    public let name = "index"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count == 2,
            let array = arguments[0]?.array,
            let index = arguments[1]?.int,
            index < array.count
            else { return nil }
        return array[index]
    }
}
