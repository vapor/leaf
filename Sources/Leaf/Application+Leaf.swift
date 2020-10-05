import Vapor
import LeafKit

public extension Application {
    var leaf: LeafEngine { .init(self) }
}

public extension LeafUnsafeEntity {
    var app: Application? { externalObjects?["app"] as? Application }
}

extension Application: LeafContextPublisher {
    public var coreVariables: [String : LeafDataGenerator] {
        ["isRelease": .immediate(self.environment.isRelease)]
    }
}
