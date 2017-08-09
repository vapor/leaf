import Bits

/// Renders Leaf templates using the Leaf parser and serializer.
public final class Renderer {
    /// The tags available to this renderer.
    public let tags: [String: Tag]

    /// The renderer will use this to read files for
    /// tags that require it (such as #embed)
    public let fileReader: FileReader

    /// Create a new Leaf renderer.
    public init(tags: [String: Tag]? = nil, fileReader: FileReader) {
        self.tags = tags ?? defaultTags
        self.fileReader = fileReader
    }

    // ASTs only need to be parsed once
    private var _cachedASTs: [Int: [Syntax]] = [:]

    /// Renders the supplied template bytes into a view
    /// using the supplied context.
    public func render(_ template: Bytes, context: DataRepresentable) throws -> Bytes {
        let hash = template.makeString().hashValue

        let ast: [Syntax]
        if let cached = _cachedASTs[hash] {
            ast = cached
        } else {
            let parser = Parser(template)
            do {
                ast = try parser.parse()
            } catch let error as ParserError {
                throw RenderError(source: error.source, reason: error.reason, error: error)
            }
            _cachedASTs[hash] = ast
        }

        do {
            let serializer = try Serializer(ast: ast, renderer: self, context: context.makeLeafData())
            return try serializer.serialize()
        } catch let error as SerializerError {
            throw RenderError(source: error.source, reason: error.reason, error: error)
        } catch let error as TagError {
            throw RenderError(source: error.source, reason: error.reason, error: error)
        }
    }
}

// MARK: Convenience

extension Renderer {
    /// Loads the leaf template from the supplied path.
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

    /// Renders a string template and returns a string.
    public func render(_ view: String, context: DataRepresentable) throws -> String {
        return try render(view.makeBytes(), context: context).makeString()
    }
}
