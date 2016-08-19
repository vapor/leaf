final class Else: Tag {
    let name = "else"
    func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        return nil
    }
    func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Any?) -> Bool {
        return true
    }
}
