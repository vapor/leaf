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
            throw "unable to chain \(chainedInstruction) w/o preceding tagTemplate"
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
            return ".raw(\(r.string))"
        case let .tagTemplate(i):
            return ".tagTemplate(\(i))"
        case let .chain(chain):
            return ".chain(\(chain))"
        }
    }
}
