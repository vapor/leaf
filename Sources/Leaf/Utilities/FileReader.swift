import Bits

public protocol FileReader {
    func read(at path: String) throws -> Bytes
}
