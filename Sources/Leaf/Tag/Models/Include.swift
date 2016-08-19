public final class Include: Tag {
    public let name = "include"

    public func postCompile(
        stem: Stem,
        tagTemplate: TagTemplate) throws -> TagTemplate {
        guard tagTemplate.parameters.count == 1 else {
            throw "invalid include"
        }
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

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]) throws -> Any? {
        return nil
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
        value: Any?) -> Bool {
        // throws at precompile, should always render
        return true
    }
}
