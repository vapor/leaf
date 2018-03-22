import Async
import Dispatch
import Foundation
import Service
import TemplateKit

public final class LeafProvider: Provider {
    /// See Service.Provider.repositoryName
    public static let repositoryName = "leaf"

    public init() {}

    /// See Service.Provider.Register
    public func register(_ services: inout Services) throws {
        services.register(TemplateRenderer.self) { container -> LeafRenderer in
            let config = try container.make(LeafConfig.self)
            return LeafRenderer(
                config: config,
                using: container
            )
        }

        services.register { container -> LeafConfig in
            let dir = try container.make(DirectoryConfig.self)
            return try LeafConfig(
                tags: container.make(),
                viewsDir: dir.workDir + "Resources/Views",
                shouldCache: container.environment != .development
            )
        }

        services.register { container -> LeafTagConfig in
            return LeafTagConfig.default()
        }
    }

    /// See Service.Provider.boot
    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}
