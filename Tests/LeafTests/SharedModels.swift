@testable import Leaf

let stem = Stem()

class Test: Tag {
    let name: String
    let value: Node?
    let shouldRender: Bool

    init(name: String, value: Node?, shouldRender: Bool) {
        self.name = name
        self.value = value
        self.shouldRender = shouldRender
    }

    func run(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Node? {
        return value
    }

    func shouldRender(stem: Stem, context: Context, tagTemplate: TagTemplate, arguments: [Argument], value: Node?) -> Bool {
        return shouldRender
    }
}
