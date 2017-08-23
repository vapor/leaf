import Core
import Dispatch
import Foundation
import Leaf
import libc

extension Renderer {
    static func makeTestRenderer() -> Renderer {
        return Renderer(fileReader: TestFiles())
    }
}

extension String: Error { }

final class TestFiles: FileReader {
    init() {}


    func read(at path: String) -> Future<Data> {
        let data = """
            Test file name: "\(path)"
            """.data(using: .utf8)!

        let promise = Promise(Data.self)
        promise.complete(data)
        return promise.future
    }
}

final class PreloadedFiles: FileReader {
    var files: [String: Data]
    init() {
        files = [:]
    }

    func read(at path: String) -> Future<Data> {
        let promise = Promise(Data.self)

        if let data = files[path] {
            promise.complete(data)
        } else {
            promise.fail("Could not find file")
        }

        return promise.future
    }
}

final class NonblockingFiles: FileReader {
    let queue: DispatchQueue
    var cache: [String: Data]

    var sources: [Int32: DispatchSourceRead]

    init(on queue: DispatchQueue) {
        self.queue = queue
        self.cache = [:]
        self.sources = [:]
    }

    func read(at path: String) -> Future<Data> {
        let promise = Promise(Data.self)

        let fd = libc.open(path.withCString { $0 }, O_RDONLY | O_NONBLOCK)
        let readSource = DispatchSource.makeReadSource(
            fileDescriptor: fd,
            queue: queue
        )

        readSource.setEventHandler {
            var chars: [UInt8] = [UInt8](repeating: 0, count: 512)
            let bytesRead = libc.read(fd, &chars, chars.count)
            let view = Array(chars[0..<bytesRead])
            let data = Data(bytes: view)
            promise.complete(data)
            self.sources[fd] = nil
        }
        readSource.resume()

        sources[fd] = readSource
        return promise.future;
    }
}
