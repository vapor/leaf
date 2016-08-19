final class If: Tag {
    let name = "if"

    func run(
        stem: Stem,
        filler: Scope,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        guard arguments.count == 1 else { throw "invalid if statement arguments" }
        return nil
    }

    func shouldRender(
        stem: Stem,
        filler: Scope,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Any?) -> Bool {
        guard arguments.count == 1 else { return false }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            let bool = Bool(value)
            return bool == true
        case let .variable(key: _, value: value as Bool):
            return value
        case let .variable(key: _, value: value as String):
            let bool = Bool(value)
            return bool == true
        case let .variable(key: _, value: value as Int):
            return value == 1
        case let .variable(key: _, value: value as Double):
            return value == 1.0
        case let .variable(key: _, value: value):
            return value != nil
        }
    }
}
