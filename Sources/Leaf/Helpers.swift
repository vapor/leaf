import Vapor

internal typealias ELF = EventLoopFuture
internal typealias LFMIndexing = LeafFileMiddleware.DirectoryIndexing
internal typealias Record = (process: Bool, modTime: Date)

internal extension Request {
    var eL: EventLoop { eventLoop }
    func fail<T>(_ error: Error) -> ELF<T> { eL.makeFailedFuture(error) }
    func succeed<T>(_ value: T) -> ELF<T> { eL.makeSucceededFuture(value) }
}

internal extension LeafEngine {
    var eL: EventLoop { eventLoop }
    func fail<T>(_ error: Error) -> ELF<T> { eL.makeFailedFuture(error) }
    func succeed<T>(_ value: T) -> ELF<T> { eL.makeSucceededFuture(value) }
}

internal extension String {
    var fileExt: String {
        if let i = lastIndex(of: ".") { return String(self[index(after: i)..<endIndex]) }
        return ""
    }
}
