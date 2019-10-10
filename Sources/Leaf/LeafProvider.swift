import Vapor

public final class LeafProvider: Provider {
    public init() { }
    
    public func register(_ s: inout Services) {
        s.register(LeafRenderer.self) { c in
            return try LeafRenderer(
                config: c.make(),
                threadPool: c.application.threadPool,
                eventLoop: c.eventLoop
            )
        }

        s.register(ViewRenderer.self) { c in
            return try c.make(LeafRenderer.self)
        }

        s.register(LeafConfig.self) { c in
            let directory = try c.make(DirectoryConfiguration.self)
            return LeafConfig(rootDirectory: directory.viewsDirectory)
        }
    }
}

extension LeafRenderer: ViewRenderer {
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
