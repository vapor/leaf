import Bits

public final class Renderer {
    public let tags: [String: Tag]
    public let fileReader: FileReader

    public init(tags: [String: Tag]? = nil, fileReader: FileReader) {
        self.tags = tags ?? defaultTags
        self.fileReader = fileReader
    }

    private var _cachedASTs: [Int: [Syntax]] = [:]

    public func render(_ view: Bytes, context: DataRepresentable) throws -> Bytes {
        let hash = view.makeString().hashValue

        let ast: [Syntax]
        if let cached = _cachedASTs[hash] {
            ast = cached
        } else {
            let parser = Parser(view)
            ast = try parser.parse()
            _cachedASTs[hash] = ast
        }

        return try render(ast, context: context)
    }

    public func render(_ ast: [Syntax], context: DataRepresentable) throws -> Bytes {
        let serializer = try Serializer(ast: ast, renderer: self, context: context.makeLeafData())
        return try serializer.serialize()
    }
}

// MARK: Convenience

extension Renderer {
    public func render(path: String, context: DataRepresentable) throws -> Bytes {
        let path = path.hasSuffix(".leaf") ? path : path + ".leaf"
        let view = try fileReader.read(at: path)
        do {
            return try render(view, context: context)
        } catch var error as RenderError {
            error.path = path
            throw error
        }
    }


    public func render(_ view: String, context: DataRepresentable) throws -> String {
        return try render(view.makeBytes(), context: context).makeString()
    }
}
