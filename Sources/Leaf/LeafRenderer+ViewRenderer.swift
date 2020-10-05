import Vapor

extension LeafEngine: ViewRenderer {
    public func `for`(_ request: Request) -> ViewRenderer { request.leaf }

    public func render<E>(_ name: String,
                          _ context: E) -> EventLoopFuture<View> where E: Encodable {
        guard let context = LeafRenderer.Context(encodable: context) else {
            return eventLoop.makeFailedFuture("Provided context failed to encode or is not a dictionary") }
        return render(template: name, context: context)
    }
}
