import Core
import Foundation

/// Used to facilitate parsing byte arrays
final class ByteScanner {
    /// Source location information
    var offset: Int
    var line: Int
    var column: Int

    /// Byte location information
    var pointer: UnsafePointer<UInt8>
    let endAddress: UnsafePointer<UInt8>
    var buffer: UnsafeBufferPointer<UInt8>
    public let data: Data

    /// Create a new byte scanner
    public init(data: Data) {
        self.data = data
        self.buffer = UnsafeBufferPointer(start: data.withUnsafeBytes { $0 }, count: data.count)
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
    func peek(by amount: Int = 0) -> UInt8? {
        guard pointer.advanced(by: amount) < endAddress else {
            return nil
        }
        return pointer.advanced(by: amount).pointee
    }

    /// Returns current byte and increments byte pointer.
    func pop() -> UInt8? {
        guard pointer != endAddress else {
            return nil
        }

        defer {
            pointer = pointer.advanced(by: 1)
            offset = offset &+ 1
        }
        let element = pointer.pointee
        column = column &+ 1
        if element == .newLine {
            line = line &+ 1
            column = 0
        }
        return element
    }
}

extension ByteScanner {
    fileprivate func advancePointer() {
        defer {
            pointer = pointer + 1
            offset = offset &+ 1
        }
        
        column = column &+ 1
        
        if pointer.pointee == .newLine {
            line = line &+ 1
            column = 0
        }
    }
    
    // extracts bytes until an unescaped signal byte is found.
    // note: escaped bytes have the leading `\` removed
    internal func extractBytes(untilUnescaped signalBytes: [Byte]) -> Data {
        var bytes = Data()
        
        var onlySpacesExtracted = true
        var offset = 0
        
        // Scan until the end of the buffer (until the signal)
        endBufferScan: while pointer + offset < endAddress {
            // Stop if we find the signal
            if signalBytes.contains(pointer[offset]) {
                break endBufferScan
            }
            
            offset = offset &+ 1
        }
        
        // Set up the end of the buffer's pointer
        let endOfBuffer = pointer.advanced(by: offset)
        
        // Reserve capacity, preventing many reallocations
        bytes.reserveCapacity(offset)
        
        // continue to peek until we fine a signal byte, then exit!
        // the inner loop takes care that we will not hit any
        // properly escaped signal bytes
        while pointer < endOfBuffer {
            let byte = pointer.pointee
            
            advancePointer()
            
            // if the current byte is a backslash, then
            // we need to check if next byte is a signal byte
            if byte == .backSlash {
                // check if the next byte is a signal byte
                // note: special case, any raw leading with a left curly must
                // be properly escaped (have the \ removed)
                if pointer < endAddress, signalBytes.contains(pointer.pointee) || onlySpacesExtracted && pointer.pointee == .leftCurlyBracket {
                    // if it is, it has been properly escaped.
                    // add it now, skipping the backslash and popping
                    // so the next iteration of this loop won't see it
                    bytes.append(pointer.pointee)
                    advancePointer()
                } else {
                    // just a normal backslash
                    bytes.append(byte)
                }
            } else {
                // just a normal byte
                bytes.append(byte)
            }
            
            if byte != .space {
                onlySpacesExtracted = false
            }
        }
        
        return bytes
    }
}
