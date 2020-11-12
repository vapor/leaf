import Vapor
import LeafKit

extension LeafRenderer: ViewRenderer {
    public func `for`(_ request: Request) -> ViewRenderer {
        request.leaf
    }

    public func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View>
        where E: Encodable
    {
        let data: [String: LeafData]
        do {
            data = try LeafEncoder().encode(context)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        return self.render(path: name, context: data).map { buffer in
            return View(data: buffer)
        }
    }
}
