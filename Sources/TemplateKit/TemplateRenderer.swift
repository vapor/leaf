import Async
import Foundation

/// Renders templates to views.
public protocol TemplateRenderer: class, Worker {
    /// The available tags.
    var tags: [String: TagRenderer] { get }

    /// Parses the template data into an AST.
    /// See `TemplateParser`.
    var parser: TemplateParser { get }

    /// Used to cache parsed ASTs for performance.
    /// If `nil`, caching will be skipped.
    var astCache: ASTCache? { get set }

    /// The specific template file ending.
    var templateFileEnding: String { get }

    /// Relative leading directory for none absolute paths.
    var relativeDirectory: String { get }
}

extension TemplateRenderer {
    // ASTs only need to be parsed once
    /// Renders the supplied template bytes into a view
    /// using the supplied context.
    public func render(template: Data, _ context: TemplateData) -> Future<View> {
        return Future {
            let hash = template.hashValue
            let ast: [TemplateSyntax]
            if let cached = self.astCache?.storage[hash] {
                ast = cached
            } else {
                ast = try self.parser.parse(template: template)
                self.astCache?.storage[hash] = ast
            }

            let serializer = TemplateSerializer(
                renderer: self,
                context: .init(data: context),
                on: self
            )
            return serializer.serialize(ast: ast)
        }
    }
}

// MARK: Convenience

extension TemplateRenderer {
    /// Loads the leaf template from the supplied path.
    public func render(_ path: String, _ context: Encodable) -> Future<View> {
        let path = path.hasSuffix(templateFileEnding) ? path : path + templateFileEnding
        let absolutePath = path.hasPrefix("/") ? path : relativeDirectory + path

        guard let data = FileManager.default.contents(atPath: absolutePath) else {
            fatalError()
        }

        let context = try! TemplateDataEncoder().encode(context)
        return render(template: data, context)
    }
}

extension TemplateRenderer {
    /// Create a view with null context.
    public func render(_ path: String) -> Future<View> {
        return render(path, "")
    }
}


/// Caches parsed ASTs.
public struct ASTCache {
    /// Internal AST storage.
    internal var storage: [Int: [TemplateSyntax]]

    /// Creates a new AST cache.
    public init() {
        storage = [:]
    }
}
