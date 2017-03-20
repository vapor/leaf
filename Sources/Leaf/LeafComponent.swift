extension Leaf {
    public enum Component {
        case raw(Bytes)
        case tagTemplate(TagTemplate)
        case chain([TagTemplate])
    }
}

extension Leaf.Component {
    internal mutating func addToChain(_ chainedInstruction: TagTemplate) throws {
        switch self {
        case .raw(_):
            throw ParseError.expectedLeadingTemplate(have: self)
        case let .tagTemplate(current):
            self = .chain([current, chainedInstruction])
        case let .chain(chain):
            self = .chain(chain + [chainedInstruction])
        }
    }
}

extension Leaf.Component: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .raw(r):
            return ".raw(\(r.makeString()))"
        case let .tagTemplate(i):
            return ".tagTemplate(\(i))"
        case let .chain(chain):
            return ".chain(\(chain))"
        }
    }
}

extension Leaf.Component: Equatable {}
public func == (lhs: Leaf.Component, rhs: Leaf.Component) -> Bool {
    switch (lhs, rhs) {
    case let (.raw(l), .raw(r)):
        return l == r
    case let (.tagTemplate(l), .tagTemplate(r)):
        return l == r
    case let (.chain(l), .chain(r)):
        return l == r
    default:
        return false
    }
}
