import Foundation

extension Sequence where Iterator.Element == Byte {
    internal static func load(path: String) throws -> Bytes {
        return try DataFile().load(path: path)
    }
}
