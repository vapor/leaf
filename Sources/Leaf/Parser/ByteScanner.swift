import Bits

/// Used to facilitate parsing byte arrays
final class ByteScanner {
    /// Source location information
    var offset: Int
    var line: Int
    var column: Int

    /// Byte location information
    var pointer: UnsafePointer<Byte>
    let endAddress: UnsafePointer<Byte>
    var buffer: UnsafeBufferPointer<Byte>
    public let bytes: Bytes

    /// Create a new byte scanner
    public init(_ bytes: Bytes) {
        self.bytes = bytes
        self.buffer = bytes.withUnsafeBufferPointer { $0 }
        self.pointer = buffer.baseAddress!
        self.endAddress = buffer.baseAddress!.advanced(by: buffer.endIndex)
        self.offset = 0
        self.line = 0
        self.column = 0
    }
}

// MARK: Core

extension ByteScanner {
    /// Peeks ahead to bytes in front of current byte
    func peek(by amount: Int = 0) -> Byte? {
        guard pointer.advanced(by: amount) < endAddress else {
            return nil
        }
        return pointer.advanced(by: amount).pointee
    }

    /// Returns current byte and increments byte pointer.
    func pop() -> Byte? {
        guard pointer != endAddress else {
            return nil
        }

        defer {
            pointer = pointer.advanced(by: 1)
            offset += 1
        }
        let element = pointer.pointee
        column += 1
        if element == .newLine {
            line += 1
            column = 0
        }
        return element
    }
}
