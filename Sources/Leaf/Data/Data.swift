public enum Data {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case dictionary([String: Data])
    case array([Data])
    public typealias Future = () -> (Data)
    case future(Future)
    case null
}

// MARK: Protocols

public protocol DataRepresentable {
    func makeLeafData() throws -> Data
}

extension Data: DataRepresentable {
    public func makeLeafData() throws -> Data {
        return self
    }
}

// MARK: Equatable

extension Data: Equatable {
    public static func ==(lhs: Data, rhs: Data) -> Bool {
        switch (lhs, rhs) {
        case (.array(let a), .array(let b)):
            return a == b
        case (.dictionary(let a), .dictionary(let b)):
            return a == b
        default:
            return lhs.string == rhs.string
        }
    }
}

