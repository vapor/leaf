class Index: BasicTag {
    public init() {
        super.init(name: "index")
    }

    override func run(arguments: [Argument]) throws -> Node? {
        guard
            arguments.count == 2,
            let array = arguments[0].value?.nodeArray,
            let index = arguments[1].value?.int,
            index < array.count
            else { return nil }
        return array[index]
    }
}
