import Vapor


extension Application.Leaf {
    /// Deprecated in Leaf-Kit 1.0.0rc-1.??
    @available(*, deprecated, message: "Use .sources instead of .files")
    public var files: LeafSource {
        get {
            fatalError("Unavailable")
        }
        nonmutating set {
            self.storage.sources = .singleSource(newValue)
        }
    }
}
