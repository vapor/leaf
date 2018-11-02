/// Used to configure Leaf renderer.
public struct LeafConfig: Service {
    /// Available leaf tags.
    public var tags: LeafTagConfig
    
    /// Absolute path to views directory.
    public var viewsDir: String
    
    /// If `true`, Leaf should cache parsed views.
    public var shouldCache: Bool

    /// Creates a new `LeafConfig`.
    ///
    /// - parameters:
    ///     - tags: Available leaf tags.
    ///     - viewsDir: Absolute path to views directory.
    ///     - shouldCache: If `true`, Leaf should cache parsed views.
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
