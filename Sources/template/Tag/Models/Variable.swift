final class Variable: Tag {
    let name = "" // empty name, ie: @(variable)

    func run(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Any? {
        // temporary escaping mechanism. ALL tags are interpreted, use `#()` to have an empty `#` rendered
        if arguments.isEmpty { return [TOKEN].string } // temporary escaping mechanism?
        guard arguments.count == 1 else { throw "invalid var argument" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }
}
