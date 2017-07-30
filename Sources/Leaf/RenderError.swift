public struct RenderError: Error {
    let source: Source
    let error: Error
    var path: String?

    init(source: Source, error: Error, path: String? = nil) {
        self.source = source
        self.error = error
        self.path = path
    }
}
