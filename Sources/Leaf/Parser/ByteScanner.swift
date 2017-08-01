import Bits

public final class ByteScanner {
    var offset: Int
    var line: Int
    var column: Int
    var pointer: UnsafePointer<Byte>
    let endAddress: UnsafePointer<Byte>
    var buffer: UnsafeBufferPointer<Byte>
    public let bytes: Bytes

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
    public func peek(by amount: Int = 0) -> Byte? {
        guard pointer.advanced(by: amount) < endAddress else {
            return nil
        }
        return pointer.advanced(by: amount).pointee
    }

    public func pop() -> Byte? {
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
