import LeafKit
import Vapor

extension LeafKit.LeafRenderer: Vapor.ViewRenderer {
    public func `for`(_ request: Request) -> any ViewRenderer {
        request.leaf
    }

    public func render(_ name: String, _ context: some Encodable) -> EventLoopFuture<View> {
        self.render(path: name, context: context).map { buffer in
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
    public func render(path: String, context: some Encodable) -> EventLoopFuture<ByteBuffer> {
        let data: [String: LeafData]

        do {
            data = try LeafEncoder.encode(context)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }

        return self.render(path: path, context: data)
    }
}
