import Async
import Bits
import COperatingSystem
import Dispatch
import Foundation
import Leaf

extension LeafRenderer {
    static func makeTestRenderer(worker: Worker) -> LeafRenderer {
        let config = LeafConfig { _ in
            return TestFiles()
        }
        return LeafRenderer(config: config, on: worker)
    }
}

final class PreloadedStream: Async.OutputStream, ConnectionContext {
    typealias Output = UnsafeBufferPointer<UInt8>
    let data: Data
    var downstream: AnyInputStream<UnsafeBufferPointer<UInt8>>?

    init(data: Data) {
        self.data = data
    }

    func output<S>(to inputStream: S) where S: Async.InputStream, UnsafeBufferPointer<UInt8> == S.Input {
        downstream = AnyInputStream(inputStream)
        inputStream.connect(to: self)
    }

    func connection(_ event: ConnectionEvent) {
        switch event {
        case .cancel:
            downstream = nil
        case .request:
            if let downstream = self.downstream {
                self.downstream = nil
                downstream.next(data.withByteBuffer { $0 })
                downstream.close()
            }
        }
    }
}

final class TestFiles: FileReader, FileCache {
    func read(at path: String, chunkSize: Int) -> AnyOutputStream<UnsafeBufferPointer<UInt8>> {
        let data = """
        Test file name: "\(path)"
        """.data(using: .utf8)!


        let preloaded = PreloadedStream(data: data)
        return AnyOutputStream(preloaded)
    }

    func fileExists(at path: String) -> Bool {
        return false
    }

    func directoryExists(at path: String) -> Bool {
        return false
    }

    init() {
    }

    func getCachedFile(at path: String) -> Data? {
        return nil
    }

    func setCachedFile(file: Data?, at path: String) {
        // nothing
    }
}

final class PreloadedFiles: FileReader, FileCache {
    var files: [String: Data]

    init() {
        files = [:]
    }

    func getCachedFile(at path: String) -> Data? {
        return nil
    }

    func setCachedFile(file: Data?, at path: String) {
        // nothing
    }

    func read(at path: String, chunkSize: Int) -> AnyOutputStream<UnsafeBufferPointer<UInt8>> {
        let preloaded = PreloadedStream(data: self.files[path]!)
        return AnyOutputStream(preloaded)
    }

    func directoryExists(at path: String) -> Bool {
        return false
    }

    func fileExists(at path: String) -> Bool {
        return false
    }
}

extension String: Error {}
