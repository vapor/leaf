import Vapor

public final class LeafProvider: Provider {
    public init() { }
    
    public func register(_ app: Application) {
        app.register(LeafRenderer.self) { app in
            LeafRenderer(
                config: app.make(),
                threadPool: app.make(),
                eventLoop: app.make()
            )
        }

        app.register(ViewRenderer.self) { app in
            app.make(LeafRenderer.self)
        }

        app.register(LeafConfig.self) { app in
            let directory = app.make(DirectoryConfiguration.self)
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

extension Request {
    public var leaf: LeafRenderer {
        LeafRenderer(
            config: self.application.make(),
            threadPool: self.application.make(),
            eventLoop: self.eventLoop
        )
    }
}
