/// Adds Leaf services to your container.
///
///     try services.register(LeafProvider())
///
public final class LeafProvider: Provider {
    /// Creates a new `LeafProvider`.
    public init() {}

    /// See `Provider`.
    public func register(_ services: inout Services) throws {
        services.register([TemplateRenderer.self, ViewRenderer.self]) { container -> LeafRenderer in
            return try .init(config: container.make(), using: container)
        }

        services.register { container -> LeafConfig in
            let dir = try container.make(DirectoryConfig.self)
            return try .init(
                tags: container.make(),
                viewsDir: dir.workDir + "Resources/Views",
                shouldCache: container.environment != .development
            )
        }

        services.register { container -> LeafTagConfig in
            return .default()
        }
    }

    /// See `Provider`.
    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}
