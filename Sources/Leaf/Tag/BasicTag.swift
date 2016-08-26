open class BasicTag: Tag {
    /**
        Basic tag error
    */
    public enum Error: LeafError {
        case overrideRequired(String)
    }

    /**
        Tag name
    */
    public let name: String

    /**
        Designated Initializer for name
    */
    public init(name: String) {
        self.name = name
    }

    open func run(arguments: [Argument]) throws -> Node? {
        throw Error.overrideRequired(#function)
    }

    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]
    ) throws -> Node? {
        return try run(arguments: arguments)
    }
}
