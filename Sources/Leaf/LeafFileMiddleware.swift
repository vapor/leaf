import NIOConcurrencyHelpers
import Vapor
import Foundation

/// Serves files from a public directory, interpreting as Leaf templates if the file is such.
public final class LeafFileMiddleware: Middleware {
    @LeafRuntimeGuard
    public static var defaultType: HTTPMediaType = .html
    
    @LeafRuntimeGuard
    public static var processableExtensions: Set<String> = [LeafSources.defaultExtension, "html"]
    
    /// Raw directory path is mangled into a LeafSource key in the form "_LFMdirectoryHashValue"
    private let dir: String
    private let scope: String
    
    private typealias Record = (process: Bool, modTime: Date)
    
    private static let lock: Lock = .init()
    private static var lookup: [String: Record] = [:]
      
    /// Creates a new `LeafFileMiddleware` - validates that the configured path is an existing directory.
    public init?(publicDirectory dir: String) {
        var dir = dir
        if !dir.hasSuffix("/") { dir.append("/") }
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: dir, isDirectory: &isDir)
        guard isDir.boolValue else { return nil }
        self.dir = dir
        self.scope = "_LFM\(dir.hashValue)"
    }
    
    public func respond(to request: Request,
                        chainingTo next: Responder) -> EventLoopFuture<Response> {
        func fail(_ reason: Error) -> EventLoopFuture<Response> { request.eventLoop.makeFailedFuture(reason) }
        
        /// Validate path as non-relative, non-directory reference
        let path = URL(fileURLWithPath: dir + (request.url.path.removingPercentEncoding ?? ""))
                      .standardizedFileURL.path
        guard !path.isEmpty else { return fail(badRequest) }
        if path.hasSuffix("/") { return fail(noDirIndex) }
        if path.contains("../") { return fail(noRelative) }
        
        /// And validate it exists and is definitely not a directory
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) { return next.respond(to: request) }
        if isDir.boolValue { return fail(noDirIndex) }
        
        /// Non-processable extension immediately streams
        if !Self.processableExtensions.contains(path.fileExt) { return stream(path, on: request) }
        
        var record: Record = self[path] ?? (false, .distantPast)
                
        guard let attr = try? FileManager.default.attributesOfItem(atPath: path),
              let modTime = attr[.modificationDate] as? Date else { return fail(moduleError) }
        
        /// Only check actual file contents if mod time isn't the recorded state
        if modTime != record.modTime {
            record.modTime = modTime
            let fileio = request.application.fileio
            let eL = request.eventLoop
            
            return fileio.openFile(path: path, eventLoop: request.eventLoop)
                .flatMap { file in
                    fileio.read(fileRegion: file.1, allocator: ByteBufferAllocator(), eventLoop: eL)
                        .flatMapThrowing { buffer -> ByteBuffer in try file.0.close(); return buffer }
                        .flatMap {
                            var buffer = $0
                            let src = buffer.readString(length: buffer.readableBytes) ?? ""
                            // FIXME: process check is blocking
                            record.process = LeafEngine.entities.validate(in: src) != false
                            return record.process ? self.process(path, on: request)
                                                  : self.stream(path, on: request)
                        }
                }
        }
        
        return record.process ? process(path, on: request) : stream(path, on: request)
    }
    
    /// Process as Leaf.
    private func process(_ path: String, on req: Request) -> EventLoopFuture<Response> {
        /// Ensure source for this directory is set up, fail if it isn't.
        if let failure = checkSource(req) { return failure }
        
        /// Strip path to the relative portion
        var path = path
        path.removeFirst(dir.count)
        
        /// Flatten contexts
        var context = req.application.leaf.context
        try? context.overlay(req.leaf.context)
               
        return req.leaf.renderer
            .render(template: path, from: scope, context: context)
            .map {
                var headers: HTTPHeaders = [:]
                headers.contentType = .fileExtension(path.fileExt) ?? Self.defaultType
                headers.add(name: .eTag, value: "\(Date().timeIntervalSinceReferenceDate)")
                return Response(status: .ok, headers: headers, body: .init(buffer: $0))
            }
    }
    
    private func stream(_ path: String, on req: Request) -> EventLoopFuture<Response> {
        req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: path)) }
    
    private func checkSource(_ req: Request) -> EventLoopFuture<Response>? {
        if !req.leaf.renderer.sources.all.contains(scope) {
            do { try req.leaf.renderer.sources
                 .register(source: scope,
                           using: NIOLeafFiles(fileio: req.application.fileio,
                                               sandboxDirectory: dir,
                                               viewDirectory: dir,
                                               defaultExtension: LeafSources.defaultExtension),
                           searchable: false)
            } catch { return req.eventLoop.makeFailedFuture(error) }
        }
        return nil
    }
    
    var notFound: Abort { Abort(.notFound) }
    var forbidden: Abort { Abort(.forbidden) }
    var badRequest: Abort { Abort(.badRequest) }
    var noDirIndex: Abort { Abort(.forbidden, reason: "Directory indexing disallowed") }
    var noRelative: Abort { Abort(.forbidden, reason: "Relative paths disallowed") }
    var moduleError: Abort { Abort(.internalServerError, reason: "LeafFileMiddleware internal error") }
        
    private subscript(path: String) -> Record? {
        get { Self.lock.withLock { Self.lookup[path] } }
        set { Self.lock.withLockVoid { Self.lookup[path] = newValue } }
    }
}

private extension String {
    var fileExt: String {
        if let i = lastIndex(of: ".") { return String(self[index(after: i)..<endIndex]) }
        return ""
    }
}
