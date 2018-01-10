import Async
import Bits
import Dispatch
import Foundation

/// Renders Leaf templates using the Leaf parser and serializer.
public final class LeafRenderer {
    /// The tags available to this renderer.
    public let tags: [String: LeafTag]

    /// The renderer will use this to read files for
    /// tags that require it (such as #embed)
    private var _files: [Int: FileReader & FileCache]

    /// Create a file reader & cache for the supplied queue
    public typealias FileFactory = (EventLoop) -> (FileReader & FileCache)
    private let fileFactory: FileFactory

    /// Views base directory.
    public let viewsDir: String

    /// The event loop this leaf renderer will use
    /// to read files and cache ASTs on.
    let eventLoop: EventLoop
    
    /// If `true`, caches leaf templates
    let cache: Bool

    /// Create a new Leaf renderer.
    public init(
        config: LeafConfig,
        on worker: Worker,
        caching: Bool = true
    ) {
        self.tags = config.tags
        self._files = [:]
        self.fileFactory = config.fileFactory
        self.eventLoop = worker.eventLoop
        self.cache = caching
        self.viewsDir = config.viewsDir.finished(with: "/")
    }
}
