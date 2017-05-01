public protocol BasicTag: Tag {
    func run(arguments: ArgumentList) throws -> Node?
}

extension BasicTag {
    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList
        ) throws -> Node? {
        return try run(arguments: arguments)
    }
}
