import Vapor

public final class LeafProvider: Provider {
    public init() { }
    
    public func register(_ app: Application) {
        app.register(LeafRenderer.self) { c in
            return LeafRenderer(
                config: c.make(),
                threadPool: c.make(),
                eventLoop: c.make()
            )
        }

        app.register(ViewRenderer.self) { c in
            return c.make(LeafRenderer.self)
        }

        app.register(LeafConfig.self) { c in
            let directory = c.make(DirectoryConfiguration.self)
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
