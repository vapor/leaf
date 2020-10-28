import Vapor

public extension Application.Views.Provider {
    static var leaf: Self {
        .init {
            /// Pull  the Vapor directory, or leave as set if user has configured directly
            let detected = LeafEngine.rootDirectory ?? $0.directory.viewsDirectory
            LeafEngine.rootDirectory = detected
            /// Initialize sources to file-based reader with default settings if set with no sources (default)
            if LeafEngine.sources.all.isEmpty {
                LeafEngine.sources = .singleSource(NIOLeafFiles(fileio: $0.fileio,
                                                                limits: .default,
                                                                sandboxDirectory: detected,
                                                                viewDirectory: detected))
            }
            _ = LeafEngine.entities
            /// Prime `app` context
            _ = $0.leaf.context
            $0.views.use { $0.leaf }
        }
    }
}
