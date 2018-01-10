import Bits
import Foundation

/// Used to facilitate parsing byte arrays
public final class TemplateByteScanner {
    /// TemplateSource location information
    public var offset: Int
    public var line: Int
    public var column: Int

    /// Byte location information
    var pointer: UnsafePointer<UInt8>
    let endAddress: UnsafePointer<UInt8>
    var buffer: UnsafeBufferPointer<UInt8>
    public let data: Data

    /// Create a new byte scanner
    public init(data: Data) {
        self.data = data
        self.buffer = data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            return UnsafeBufferPointer(start: pointer, count: data.count)
        }

        self.pointer = buffer.baseAddress!
        self.endAddress = buffer.baseAddress!.advanced(by: buffer.endIndex)
        self.offset = 0
        self.line = 0
        self.column = 0
    }
}

// MARK: Core

extension TemplateByteScanner {
    /// Peeks ahead to bytes in front of current byte
    public func peek(by amount: Int = 0) -> UInt8? {
        guard pointer.advanced(by: amount) < endAddress else {
            return nil
        }
        return pointer.advanced(by: amount).pointee
    }

    /// Returns current byte and increments byte pointer.
    public func pop() -> UInt8? {
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

extension TemplateByteScanner {
    @discardableResult
    public func requirePop() throws -> Byte {
        let start = makeSourceStart()
        guard let byte = pop() else {
            fatalError("Unexpected EOF at \(makeSource(using: start))")
        }
        return byte
    }

    public func requirePop(n: Int) throws {
        for _ in 0..<n {
            try requirePop()
        }
    }

    public func peekMatches(_ bytes: [Byte]) -> Bool {
        var iterator = bytes.makeIterator()
        var i = 0
        while let next = iterator.next() {
            switch peek(by: i) {
            case next:
                i += 1
                continue
            default:
                return false
            }
        }

        return true
    }
}
