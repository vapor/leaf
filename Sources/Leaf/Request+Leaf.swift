import Vapor
import LeafKit

public extension Request {
    var leaf: LeafEngine { .init(self.application, self) }
}

public extension LeafUnsafeEntity {
    var req: Request? { unsafeObjects?["req"] as? Request }
}

extension Request: LeafContextPublisher {
    public var variables: [String : LeafDataGenerator] { [:] }
}
