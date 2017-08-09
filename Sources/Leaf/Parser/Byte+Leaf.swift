import Bits

/// Leaf specific byte helpers
extension Byte {
    func makeString() -> String {
        return [self].makeString()
    }

    var isAllowedInIdentifier: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .period
    }

    var isAllowedInTagName: Bool {
        return isAlphanumeric || self == .hyphen || self == .underscore || self == .colon || self == .forwardSlash || self == .asterisk
    }
    
    // FIXME: add to core
    static let pipe: Byte = 0x7C
}

func ~=(pattern: Byte, value: Byte?) -> Bool {
    return pattern == value
}
