import Bits

struct Buffer: BufferProtocol {
    typealias Element = Byte

    private(set) var previous: Byte? = nil
    private(set) var current: Byte? = nil
    private(set) var next: Byte? = nil

    private(set) var line: Int = 1
    private(set) var column: Int = 0

    private var buffer: IndexingIterator<[Byte]>

    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Byte {
        buffer = sequence.array.makeIterator()
        // queue up first
        moveForward() // sets next
        moveForward() // sets current
    }

    @discardableResult
    mutating func moveForward() -> Byte? {
        previous = current
        current = next
        next = self.getNext()
        return current
    }

    private mutating func getNext() -> Byte? {
        let next = buffer.next()

        if next == .newLine {
            line += 1
            column = 0
        } else {
            column += 1
        }

        return next
    }
}
