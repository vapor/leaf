public final class TagTemplate {
    public let name: String
    public let parameters: [Parameter]

    public let body: Leaf?

    internal let isChain: Bool

    internal convenience init(name: String, parameters: [Parameter], body: String?) throws {
        let body = try body.flatMap { try Leaf(raw: $0) }
        self.init(name: name, parameters: parameters, body: body)
    }


    internal init(name: String, parameters: [Parameter], body: Leaf?) {
        // we strip leading token, if another one is there,
        // that means we've found a chain element, ie: @@else {
        if name.bytes.first == TOKEN {
            self.isChain = true
            self.name = name.bytes.dropFirst().string
        } else {
            self.isChain = false
            self.name = name
        }

        self.parameters = parameters
        self.body = body
    }
}

extension TagTemplate {
    func makeArguments(context: Context) -> [Argument] {
        return parameters.map { arg in
            switch arg {
            case let .variable(path: path):
                // let value = context.get(path: key)
                let value = context.get(path: path)
                // let value = Optional(Node("World"))
                return .variable(path: path, value: value)
            case let .constant(c):
                return .constant(value: c)
            }
        }
    }
}

extension TagTemplate: CustomStringConvertible {
    public var description: String {
        return "(name: \(name), parameters: \(parameters), body: \(body)"
    }
}


extension TagTemplate: Equatable {}
public func == (lhs: TagTemplate, rhs: TagTemplate) -> Bool {
    return lhs.name == rhs.name
        && lhs.parameters == rhs.parameters
    // TODO: 
    // && lhs.body == rhs.body
}
