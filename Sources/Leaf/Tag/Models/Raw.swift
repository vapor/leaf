final class Raw: Tag {
    let name = "raw"

    func compileBody(stem: Stem, raw: String) throws -> Leaf {
        let component = Leaf.Component.raw(raw.makeBytes())
        return Leaf(raw: raw, components: [component])
    }

    func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard let string = arguments[0]?.string else { return nil }
        let unescaped = string.makeBytes()
        return .bytes(unescaped)
    }

    func shouldRender(tagTemplate: TagTemplate, arguments: ArgumentList, value: Node?) -> Bool {
        return true
    }
}
