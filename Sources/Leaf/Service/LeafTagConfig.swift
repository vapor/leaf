/// Available Leaf tags.
public struct LeafTagConfig: Service {
    /// Default Leaf tag configuration.
    public static func `default`() -> LeafTagConfig {
        return .init(storage: defaultTags)
    }
    
    /// Internal storage.
    var storage: [String: TagRenderer]
    
    /// Adds a Leaf tag to the config.
    ///
    ///     config.use(DateTag(), as: "date")
    ///
    /// - parameters:
    ///     - tag: `TagRenderer` to use.
    ///     - name: String name to reference tag in Leaf templates.
    public mutating func use(_ tag: TagRenderer, as name: String) {
        self.storage[name] = tag
    }
}
