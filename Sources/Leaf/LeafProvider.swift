import Vapor

public final class LeafProvider: Provider {
    public init() { }
    
    public func register(_ s: inout Services) throws {
        s.register(LeafRenderer.self) { c in
            return try LeafRenderer(config: c.make(), threadPool: c.make(), eventLoop: c.eventLoop)
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
        let data = try! LeafEncoder().encode(context)
        return self.render(path: name, context: data).map { buffer in
            return View(data: buffer)
        }
    }
}
