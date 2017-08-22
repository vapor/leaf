import Foundation

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
    public func render(_ template: Data, context: Context) throws -> Data {
        let hash = template.hashValue

        let ast: [Syntax]
        if let cached = _cachedASTs[hash] {
            ast = cached
        } else {
            let parser = Parser(data: template)
            do {
                ast = try parser.parse()
            } catch let error as ParserError {
                throw RenderError(source: error.source, reason: error.reason, error: error)
            }
            _cachedASTs[hash] = ast
        }

        do {
            let serializer = Serializer(ast: ast, renderer: self, context: context)
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
    public func render(path: String, context: Context, completion: @escaping (Data) -> ()) {
        let path = path.hasSuffix(".leaf") ? path : path + ".leaf"
        fileReader.read(at: path) { view in
            do {
                let data = try render(view, context: context)
                completion(data)
            } catch var error as RenderError {
                error.path = path
                // fixme: throw the error
                // throw error
            } catch {
                // fxime: do somethin
            }
        }
    }

    /// Renders a string template and returns a string.
    public func render(_ view: String, context: Context) throws -> String {
        guard let data = view.data(using: .utf8) else {
            throw "could not convert string to data"
        }

        let rendered = try render(data, context: context)

        guard let string = String(data: rendered, encoding: .utf8) else {
            throw "could not convert data to string"
        }

        return string
    }
}
