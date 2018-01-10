import Async
import Dispatch
import Foundation
import Service

/// Used to configure Leaf renderer.
public struct LeafConfig {
    let tags: [String: TagRenderer]
    let viewsDir: String
    let fileFactory: LeafRenderer.FileFactory

    public init(
        tags: [String: TagRenderer] = defaultTags,
        viewsDir: String = "/",
        fileFactory: @escaping LeafRenderer.FileFactory = File.init
    ) {
        self.tags = tags
        self.viewsDir = viewsDir
        self.fileFactory = fileFactory
    }
}

public final class LeafProvider: Provider {
    /// See Service.Provider.repositoryName
    public static let repositoryName = "leaf"

    public init() {}

    /// See Service.Provider.Register
    public func register(_ services: inout Services) throws {
        services.register(ViewRenderer.self) { container -> LeafRenderer in
            let config = try container.make(LeafConfig.self, for: LeafRenderer.self)
            return LeafRenderer(
                config: config,
                on: container,
                caching: container.environment != .development
            )
        }

        services.register { container -> LeafConfig in
            let dir = try container.make(DirectoryConfig.self, for: LeafRenderer.self)
            return LeafConfig(viewsDir: dir.workDir + "Resources/Views")
        }
    }

    /// See Service.Provider.boot
    public func boot(_ container: Container) throws { }
}
