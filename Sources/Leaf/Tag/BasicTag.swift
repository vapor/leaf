public protocol BasicTag: Tag {
    func run(arguments: [Argument]) throws -> Node?
}

extension BasicTag {
    public func run(
        stem: Stem,
        context: Context,
        tagTemplate: TagTemplate,
        arguments: [Argument]
        ) throws -> Node? {
        return try run(arguments: arguments)
    }
}
