import Service

/// Used to configure Leaf renderer.
public struct LeafConfig: Service {
    let tags: [String: TagRenderer]
    let viewsDir: String
    let shouldCache: Bool

    public init(
        tags: [String: TagRenderer],
        viewsDir: String,
        shouldCache: Bool
        ) {
        self.tags = tags
        self.viewsDir = viewsDir
        self.shouldCache = shouldCache
    }
}
