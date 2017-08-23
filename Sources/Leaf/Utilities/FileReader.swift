import Core
import Foundation

/// Capable of reading files for Leaf renderer.
public protocol FileReader {
    func read(at path: String) -> Future<Data>
}
