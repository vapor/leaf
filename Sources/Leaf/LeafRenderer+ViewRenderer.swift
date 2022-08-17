import Vapor
import LeafKit

extension LeafRenderer: ViewRenderer {
    public func `for`(_ request: Request) -> ViewRenderer {
        request.leaf
    }

    public func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View>
        where E: Encodable
    {
        return self.render(path: name, context: context).map { buffer in
            View(data: buffer)
        }
    }
}

extension LeafRenderer {
    /// Populate the template at `path` with the data from `context`.
    ///
    /// - Parameters:
    ///   - path: The name of the template to render.
    ///   - context: Contextual data to render the template with.
    /// - Returns: The serialized bytes of the rendered template.
    public func render<Context>(path: String, context: Context) -> EventLoopFuture<ByteBuffer>
        where Context: Encodable
    {
        let data: [String: LeafData]
        do {
            data = try LeafEncoder.encode(context)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }

        return self.render(path: path, context: data)
    }
}
