import Async

/// Renders templates to views.
public protocol TemplateRenderer {
    var tags: [String: TagRenderer] { get }
    
    /// Renders a view using the supplied encodable context and worker.
    func make<E>(_ path: String, _ context: E) throws -> Future<View>
        where E: Encodable
}

extension TemplateRenderer {
    /// Create a view with null context.
    public func make(_ path: String) throws -> Future<View> {
        return try make(path, nil as String?)
    }
}
