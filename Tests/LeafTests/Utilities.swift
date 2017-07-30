import Leaf
import Core

extension Renderer {
    static func makeTestRenderer() -> Renderer {
        return Renderer(file: TestFiles())
    }
}

final class TestFiles: FileProtocol {
    init() {}

    func read(at path: String) throws -> Bytes {
        return """
            Test file name: "\(path)"
            """.makeBytes()
    }

    func write(_ bytes: Bytes, to path: String) throws {
        throw "not implemented"
    }

    func delete(at path: String) throws {
        throw "not implemented"
    }
}

