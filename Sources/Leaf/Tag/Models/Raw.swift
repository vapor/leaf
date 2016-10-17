final class Raw: Tag {
    let name = "raw"

    func compileBody(stem: Stem, raw: String) throws -> Leaf {
        let component = Leaf.Component.raw(raw.bytes)
        return Leaf(raw: raw, components: [component])
    }

    func run(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Node? {
        guard let string = arguments.first?.value?.string else { return nil }
        let unescaped = string.bytes
        return .bytes(unescaped)
    }

    func shouldRender(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument], value: Node?) -> Bool {
        return true
    }
}
