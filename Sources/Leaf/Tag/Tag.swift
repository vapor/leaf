public protocol Tag {
    // ** required
    var name: String { get }

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
    ) throws -> [Argument]


    // ** Required
    // run the tag w/ the specified arguments and returns the value to add to context or render
    func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]
    ) throws -> Node?

    // whether or not the given value should be rendered. Defaults to `!= nil`
    func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
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
    ) throws -> [Argument]{
        return tagTemplate.makeArguments(context: context)
    }

    public func shouldRender(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument],
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
