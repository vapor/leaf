import Vapor
import LeafKit

public extension Request {
    var leaf: LeafEngine { .init(self.application, self) }
}

public extension LeafUnsafeEntity {
    var req: Request? { externalObjects?["req"] as? Request }
}

extension Request: LeafContextPublisher {
    public var coreVariables: [String : LeafDataGenerator] {
        ["url": .lazy(["isSecure": LeafData.bool(self.url.scheme?.contains("https")),
                        "host": LeafData.string(self.url.host),
                        "port": LeafData.int(self.url.port),
                        "path": LeafData.string(self.url.path),
                        "query": LeafData.string(self.url.query)])
        ]
    }
}
