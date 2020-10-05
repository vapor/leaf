import LeafKit
import NIOConcurrencyHelpers

internal var projectFolder: String { "/\(#file.split(separator: "/").dropLast(3).joined(separator: "/"))/" }
internal var templateFolder: String { projectFolder + "Views/" }

/// Helper `LeafFiles` struct providing an in-memory thread-safe map of "file names" to "file data"
internal final class LeafTestFiles: LeafSource {
    var files: [String: String] {
        get { lock.withLock {_files} }
        set { lock.withLockVoid {_files = newValue} }
    }
    
    var _files: [String: String]
    var lock: Lock

    init() {
        _files = [:]
        lock = .init()
    }

    public func file(template: String, escape: Bool = false, on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        var path = template
        if path.split(separator: "/").last?.split(separator: ".").count ?? 1 < 2,
           !path.hasSuffix(".leaf") { path += ".leaf" }
        if !path.hasPrefix("/") { path = "/" + path }

        return lock.withLock {
            if let file = _files[path] {
                var buffer = ByteBufferAllocator().buffer(capacity: file.count)
                buffer.writeString(file)
                return eventLoop.makeSucceededFuture(buffer)
            } else { return eventLoop.makeFailedFuture(LeafError(.noTemplateExists(template))) }
        }
    }
}
