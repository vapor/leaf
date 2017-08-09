import Leaf
import Bits

extension Renderer {
    static func makeTestRenderer() -> Renderer {
        return Renderer(fileReader: TestFiles())
    }
}

final class TestFiles: FileReader {
    init() {}

    func read(at path: String) throws -> Bytes {
        return """
            Test file name: "\(path)"
            """.makeBytes()
    }
}

