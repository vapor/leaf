open class BasicTag: Tag {
    public let name: String
    public init(name: String) {
        self.name = name
    }

    open func run(arguments: [Argument]) throws -> Node? {
        fatalError("override \(#function) required")
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
