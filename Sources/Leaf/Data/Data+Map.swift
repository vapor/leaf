import Mapper

extension Data: MapConvertible {
    public init(map: Map) throws {
        switch map {
        case .dictionary(let dict):
            self = try .dictionary(dict.mapValues { try Data(map: $0) })
        case .array(let array):
            self = try .array(array.map { try Data(map: $0) })
        case .bool(let bool):
            self = .bool(bool)
        case .double(let double):
            self = .double(double)
        case .int(let int):
            self = .int(int)
        case .null:
            self = .null
        case .string(let string):
            self = .string(string)
        }
    }

    public func makeMap() throws -> Map {
        switch self {
        case .array(let array):
            return try .array(array.map { try $0.makeMap() })
        case .bool(let bool):
            return .bool(bool)
        case .dictionary(let dict):
            return try .dictionary(dict.mapValues { try $0.makeMap() })
        case .double(let double):
            return .double(double)
        case .future(let future):
            return try future().makeMap()
        case .int(let int):
            return .int(int)
        case .null:
            return .null
        case .string(let string):
            return .string(string)
        }
    }
}

extension Data: Polymorphic { }
