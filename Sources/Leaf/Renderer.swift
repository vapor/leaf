import Bits
import Core

public final class Renderer {
    public let tags: [String: Tag]
    public let file: FileProtocol

    public init(tags: [String: Tag]? = nil, file: FileProtocol) {
        self.tags = tags ?? defaultTags
        self.file = file
    }

    private var _cachedASTs: [Int: [Syntax]] = [:]

    public func render(_ view: Bytes, context: Data) throws -> Bytes {
        let hash = view.makeString().hashValue

        let ast: [Syntax]
        if let cached = _cachedASTs[hash] {
            ast = cached
        } else {
            let parser = Parser(view)
            ast = try parser.parse()
            _cachedASTs[hash] = ast
        }

        let serializer = Serializer(ast: ast, renderer: self, context: context)
        return try serializer.serialize()
    }
}

// MARK: Convenience

extension Renderer {
    public func render(path: String, context: Data) throws -> Bytes {
        let path = path.finished(with: ".leaf")
        let view = try file.read(at: path)
        do {
            return try render(view, context: context)
        } catch var error as RenderError {
            error.path = path
            throw error
        }
    }


    public func render(_ view: String, context: Data) throws -> String {
        return try render(view.makeBytes(), context: context).makeString()
    }
}
