import Foundation

extension Sequence where Iterator.Element == Byte {
    internal static func load(path: String) throws -> Bytes {
        guard let data = NSData(contentsOfFile: path) else {
            throw "unable to load bytes \(path)"
        }
        var bytes = Bytes(repeating: 0, count: data.length)
        data.getBytes(&bytes, length: bytes.count)
        return bytes
    }
}
