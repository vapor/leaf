import Service

/// Used to configure Leaf renderer.
public struct LeafConfig: Service {
    let tags: LeafTagConfig
    let viewsDir: String
    let shouldCache: Bool

    public init(
        tags: LeafTagConfig,
        viewsDir: String,
        shouldCache: Bool
    ) {
        self.tags = tags
        self.viewsDir = viewsDir
        self.shouldCache = shouldCache
    }
}

public struct LeafTagConfig: Service {
    var storage: [String: TagRenderer]

    public mutating func use(_ tag: TagRenderer, as name: String) {
        self.storage[name] = tag
    }

    public static func `default`() -> LeafTagConfig {
        return .init(storage: defaultTags)
    }
}
