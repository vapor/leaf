public final class Else: Tag {
    public let name = "else"
    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList) throws -> Node? {
        return nil
    }
    public func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?) -> Bool {
        return true
    }
}
