public enum Parameter {
    // TODO: Store as [String]
    case variable(path: [String])
    case constant(value: String)
}

extension Parameter: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .variable(v):
            return ".variable(\(v))"
        case let .constant(c):
            return ".constant(\(c))"
        }
    }
}

extension Parameter: Equatable {}
public func == (lhs: Parameter, rhs: Parameter) -> Bool {
    switch (lhs, rhs) {
    case let (.variable(l), .variable(r)):
        return l == r
    case let (.constant(l), .constant(r)):
        return l == r
    default:
        return false
    }
}

extension Parameter {
    init<S: Sequence where S.Iterator.Element == Byte>(_ bytes: S) throws {
        let bytes = bytes.array.trimmed(.whitespace)
        guard !bytes.isEmpty else { throw "invalid argument: empty" }
        if bytes.count > 1, bytes.first == .quotationMark, bytes.last == .quotationMark {
            self = .constant(value: bytes.dropFirst().dropLast().string)
        } else {
            let path = bytes.split(separator: .period, omittingEmptySubsequences: true)
                .map { $0.string }
            self = .variable(path: path)
        }
    }
}
