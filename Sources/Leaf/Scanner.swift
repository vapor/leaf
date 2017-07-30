public final class Scanner<Element: Equatable> {
    var offset: Int
    var pointer: UnsafePointer<Element>
    let endAddress: UnsafePointer<Element>
    var buffer: UnsafeBufferPointer<Element>
    // assuming you don't mutate no copy _should_ occur
    public let elements: [Element]

    public init(_ elements: [Element]) {
        self.elements = elements
        self.buffer = elements.withUnsafeBufferPointer { $0 }
        self.pointer = buffer.baseAddress!
        self.endAddress = buffer.endAddress
        self.offset = 0
    }
}

// MARK: Core

extension Scanner {
    public func peek(aheadBy n: Int = 0) -> Element? {
        guard pointer.advanced(by: n) < endAddress else {
            return nil
        }
        offset += n
        return pointer.advanced(by: n).pointee
    }

    /// - Precondition: index != bytes.endIndex. It is assumed before calling pop that you have
    @discardableResult
    public func pop() throws -> Element {
        guard pointer != endAddress else {
            throw "Out of range"
        }
        defer {
            pointer = pointer.advanced(by: 1)
            offset += 1
        }
        return pointer.pointee
    }

    /// - Precondition: index != bytes.endIndex. It is assumed before calling pop that you have
    public func advance(_ n: Int) throws {
        guard pointer.advanced(by: n) <= endAddress else {
            throw "Out of range"
        }
        offset += n
        pointer = pointer.advanced(by: n)
    }
}

// MARK: Convenience

extension Scanner {
    public func hasPrefix(_ prefix: [Element]) -> Bool {
        for (i, e) in prefix.enumerated() {
            guard peek(aheadBy: i) == e else { return false }
        }

        return false
    }
}

extension Scanner {
    public var isEmpty: Bool {
        return pointer == endAddress
    }
}

extension UnsafeBufferPointer {
    fileprivate var endAddress: UnsafePointer<Element> {
        return baseAddress!.advanced(by: endIndex)
    }
}
