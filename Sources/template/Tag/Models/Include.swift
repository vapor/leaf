final class _Include: Tag {
    let name = "include"

    // TODO: Use
    var cache: [String: Leaf] = [:]

    func postCompile(
        stem: Stem,
        tagTemplate: TagTemplate) throws -> TagTemplate {
        guard tagTemplate.parameters.count == 1 else { throw "invalid include" }
        switch tagTemplate.parameters[0] {
        case let .constant(name): // ok to be subpath, NOT ok to b absolute
            let body = try stem.loadLeaf(named: name)
            return TagTemplate(
                name: tagTemplate.name,
                parameters: [], // no longer need parameters
                body: body
            )
        case let .variable(name):
            throw "include's must not be dynamic, try `@include(\"\(name)\")"
        }
    }

    func run(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Any? {
        return nil
    }

    func shouldRender(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument], value: Any?) -> Bool {
        // throws at precompile, should always render
        return true
    }
}
