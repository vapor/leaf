import Vapor

public final class Leaf: Provider {
    public let application: Application
    
    public var cache: LeafCache {
        get {
            self.lazy(get: \._cache, as: DefaultLeafCache())
        }
        set {
            self.lazy(set: \._cache, to: newValue)
        }
    }
    var _cache: LeafCache?
    
    public var configuration: LeafConfiguration {
        get {
            self.lazy(get: \._configuration) {
                .init(rootDirectory: self.application.directory.viewsDirectory)
            }
        }
        set {
            self.lazy(set: \._configuration, to: newValue)
        }
    }
    var _configuration: LeafConfiguration?
    
    public var renderer: LeafRenderer {
        .init(
            configuration: self.configuration,
            cache: self.cache,
            fileio: self.application.fileio,
            eventLoop: self.application.eventLoopGroup.next()
        )
    }
    
    public init(_ application: Application) {
        self.application = application
    }
    
    public func register(_ app: Application) {
        app.views.use { self.renderer }
    }
}

extension Request {
    var leaf: LeafRenderer {
        .init(
            configuration: self.application.leaf.configuration,
            cache: self.application.leaf.cache,
            fileio: self.application.fileio,
            eventLoop: self.eventLoop
        )
    }
}

extension Application {
    public var leaf: Leaf {
        self.providers.require(Leaf.self)
    }
}

extension LeafRenderer: ViewRenderer {
    public func `for`(_ request: Request) -> ViewRenderer {
        LeafRenderer(
            configuration: self.configuration,
            cache: self.cache,
            fileio: self.fileio,
            eventLoop: request.eventLoop
        )
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
