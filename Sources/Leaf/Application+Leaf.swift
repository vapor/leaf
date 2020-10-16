import Vapor
import LeafKit

public extension Application {
    var leaf: LeafEngine { .init(self) }
}

public extension LeafUnsafeEntity {
    var app: Application? { unsafeObjects?["app"] as? Application }
}

extension Application: LeafContextPublisher {
    public var leafVariables: [String : LeafDataGenerator] { [:] }
}
