public final class TagTemplate {
    public let name: String
    public let parameters: [Parameter]

    public let body: Leaf?

    internal let isChain: Bool

    internal init(name: String, parameters: [Parameter], body: Leaf?) {
        // we strip leading token, if another one is there,
        // that means we've found a chain element, ie: @@else {
        if name.makeBytes().first == TOKEN {
            self.isChain = true
            self.name = name.makeBytes().dropFirst().makeString()
        } else {
            self.isChain = false
            self.name = name
        }

        self.parameters = parameters
        self.body = body
    }
}

extension TagTemplate {
    func makeArguments(with stem: Stem, in context: Context) throws -> [Argument] {
        return try parameters.map { arg in
            switch arg {
            case let .variable(path: path):
                let value = context.get(path: path)
                return .variable(path: path, value: value)
            case let .constant(c):
                let leaf = try stem.spawnLeaf(raw: c)
                return .constant(leaf)
            }
        }
    }
}

extension TagTemplate: CustomStringConvertible {
    public var description: String {
        let body = self.body?.description ?? ""
        return "(name: \(name), parameters: \(parameters), body: \(body)"
    }
}

extension TagTemplate: Equatable {}
public func == (lhs: TagTemplate, rhs: TagTemplate) -> Bool {
    return lhs.name == rhs.name
        && lhs.parameters == rhs.parameters
        && lhs.body == rhs.body
}
