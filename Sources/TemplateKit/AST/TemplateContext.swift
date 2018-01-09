/// A reference wrapper around leaf data.
public final class TemplateContext {
    /// The wrapped data
    public var data: TemplateData

    /// Create a new LeafContext
    public init(data: TemplateData) {
        self.data = data
    }
}
