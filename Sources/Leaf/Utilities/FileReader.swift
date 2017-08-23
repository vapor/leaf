import Core
import Foundation

public protocol FileReader {
    func read(at path: String) -> Future<Data>
}

extension String: Error { }

extension DispatchData {
    static var empty: DispatchData {
        let buffer = UnsafeRawBufferPointer(start: nil, count: 0)
        return DispatchData(bytes: buffer)
    }
}

extension Data {
    var dispatchData: DispatchData {
        let pointer = BytesPointer(withUnsafeBytes { $0 })
        let buffer = UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: count)
        return DispatchData(bytes: buffer)
    }
}

