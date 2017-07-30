public enum Data {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case dictionary([String: Data])
    case array([Data])
}

// MARK: Convenience Fetch

extension Data {
    public var string: String? {
        switch self {
        case .string(let string):
            return string
        case .int(let int):
            return int.description
        case .double(let double):
            return double.description
        case .bool(let bool):
            return bool.description
        default:
            return nil
        }
    }

    public var double: Double? {
        switch self {
        case .double(let double):
            return double
        case .int(let int):
            return Double(int)
        case .string(let string):
            return Double(string)
        default:
            return nil
        }
    }

    public var bool: Bool? {
        switch self {
        case .bool(let bool):
            return bool
        case .double(let double):
            switch double {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
        case .int(let int):
            switch int {
            case 1:
                return true
            case 0:
                return false
            default:
                return nil
            }
        case .string(let string):
            switch string {
            case "1", "true":
                return true
            case "0", "false":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }


    public var dictionary: [String: Data]? {
        switch self {
        case .dictionary(let dict):
            return dict
        default:
            return nil
        }
    }
}

// MARK: Convenience

extension Data {
    public static var empty: Data {
        return .dictionary([:])
    }
}
