public final class Embed: Tag {
    public enum Error: LeafError {
        case expectedSingleConstant(have: [Parameter])
    }

    public let name = "embed"

    public func postCompile(
        stem: Stem,
        tagTemplate: TagTemplate) throws -> TagTemplate {
        guard
            let parameter = tagTemplate.parameters.first,
            case let .constant(value: name) = parameter
            else {
                throw Error.expectedSingleConstant(have: tagTemplate.parameters)
            }

        let body = try stem.spawnLeaf(at: name)
        return TagTemplate(
            name: tagTemplate.name,
            parameters: [], // no longer need parameters
            body: body
        )
    }

    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList) throws -> Node? {
        return nil
    }

    public func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?) -> Bool {
        // throws at precompile, should always render
        return true
    }
}
