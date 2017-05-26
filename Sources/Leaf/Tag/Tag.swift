public protocol Tag {
    // ** required
    var name: String { get }

    func compileBody(
        stem: Stem,
        raw: String
    ) throws -> Leaf

    // after a leaf is compiled, an opportunity for specialized tags to modify the leaf itself
    func postCompile(
        stem: Stem,
        leaf: Leaf
    ) throws -> Leaf

    // after a leaf is compiled, an tagTemplate will be passed in for validation/modification if necessary
    func postCompile(
        stem: Stem,
        tagTemplate: TagTemplate
    ) throws -> TagTemplate

    // turn parameters in leaf into concrete arguments
    func makeArguments(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate
    ) throws -> ArgumentList


    // ** Required
    // run the tag w/ the specified arguments and returns the value to add to context or render
    func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList
    ) throws -> Node?

    // whether or not the given value should be rendered. Defaults to `!= nil`
    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
    ) -> Bool

    // context is populated with value at this point
    // renders a given leaf, can override for custom behavior. For example, #loop
    func render(
        stem: Stem,
        context: Context,
        value: Node?,
        leaf: Leaf
    ) throws -> Bytes
}

extension Tag {
    public func compileBody(
        stem: Stem,
        raw: String
        ) throws -> Leaf {
        return try stem.spawnLeaf(raw: raw)
    }

    public func postCompile(
        stem: Stem,
        leaf: Leaf
    ) throws -> Leaf {
        return leaf
    }

    public func postCompile(
        stem: Stem,
        tagTemplate: TagTemplate
    ) throws -> TagTemplate {
        return tagTemplate
    }

    public func makeArguments(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate
    ) throws -> ArgumentList {
        return try tagTemplate.makeArguments(with: stem, in: context)
    }

    public func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
    ) -> Bool {
        return value != nil
    }

    public func render(
        stem: Stem,
        context: Context,
        value: Node?,
        leaf: Leaf
    ) throws -> Bytes {
        return try stem.render(leaf, with: context)
    }
}
