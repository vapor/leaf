import Foundation
import Leaf

extension Renderer {
    static func makeTestRenderer() -> Renderer {
        return Renderer(fileReader: TestFiles())
    }
}

final class TestFiles: FileReader {
    init() {}


    func read(at path: String, completion: (Data) -> ()) {
        let data = """
            Test file name: "\(path)"
            """.data(using: .utf8)!
        completion(data)
    }
}

