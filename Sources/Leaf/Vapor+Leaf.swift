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
            let directory = try c.make(DirectoryConfig.self)
            return LeafConfig(rootDirectory: directory.workDir + "/Resources/Views")
        }
    }
}

public protocol LeafDataConvertible {
    var leafData: LeafData? { get }
}

extension LeafRenderer: ViewRenderer {
    public var eventLoop: EventLoop {
        #warning("TODO: make event loop public")
        fatalError()
    }

    public func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View>
        where E: Encodable
    {
        let data = try! LeafEncoder().encode(context)
        return self.render(path: name, context: data).map { buffer in
            return View(data: buffer)
        }
    }
}

public protocol ViewRenderer {
    var eventLoop: EventLoop { get }
    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View>
        where E: Encodable
}

public struct View: ResponseEncodable {
    public var data: ByteBuffer

    public init(data: ByteBuffer) {
        self.data = data
    }

    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        let response = Response()
        response.headers.contentType = .html
        response.body = .init(buffer: self.data)
        return request.eventLoop.makeSucceededFuture(response)
    }
}
