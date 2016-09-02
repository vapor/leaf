class Raw: Tag {
    let name = "raw"

    func compileBody(stem: Stem, raw: String) throws -> Leaf {
        let component = Leaf.Component.raw(raw.bytes)
        return Leaf(raw: raw, components: [component])
    }

    func run(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Node? {
        return nil
    }
    func shouldRender(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument], value: Node?) -> Bool {
        return true
    }
}
