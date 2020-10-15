import NIO
import Vapor
import LeafKit

public struct LeafEngine {
    // MARK: - Public Global Properties
    
    @LeafRuntimeGuard public static var rootDirectory: String? = nil
    
    @LeafRuntimeGuard public static var cache: LeafCache = DefaultLeafCache()
    
    @LeafRuntimeGuard public static var sources: LeafSources = .init()
    
    // MARK: - Public Stored Properties
    
    public let eventLoop: EventLoop
    
    // MARK: - Internal/Private Only
    
    struct Key: StorageKey { typealias Value = LeafEngine.Storage }
    
    final class Storage {
        var context: Context
        
        init(_ context: Context = [:]) { self.context = context }
    }
    
    init(_ app: Application, _ req: Request? = nil) {
        self.app = app
        self.req = req
        self.eventLoop = req?.eventLoop ?? app.eventLoopGroup.next()
        self.renderer = LeafRenderer(cache: LeafEngine.cache,
                                     sources: LeafEngine.sources,
                                     eventLoop: eventLoop)
        if req != nil { _ = context }
    }
    
    unowned var app: Application
    unowned var req: Request?
    
    let renderer: LeafRenderer
}

// MARK: - Public Properties & Methods

public extension LeafEngine {
    var context: LeafRenderer.Context {
        get {
            if let hit = storage?.context { return hit }
            
            let mode: (Any, String) = req != nil ? (req!, "req") : (app, "app")
            let new = Storage(.emptyContext(isRoot: req == nil))
            
            try! new.context.register(object: mode.0, toScope: mode.1, type: [.bothModes, .preventOverlay])
            storage = new
            return new.context
        }
        nonmutating set {
            if storage == nil { storage = .init() }
            storage!.context = newValue
        }
    }
    
    func render(template: String,
                context: LeafRenderer.Context = .emptyContext(),
                options: LeafRenderer.Options? = nil) -> EventLoopFuture<View> {
        var context = context
        do { try context = flattenContexts(context) }
        catch { return eventLoop.makeFailedFuture(error) }
        return renderer.render(template: template,
                               context: context,
                               options: options)
                        .map { View(data: $0) }
    }
    
    func render(template: String,
                from source: String,
                context: LeafRenderer.Context = .emptyContext(),
                options: LeafRenderer.Options? = nil) -> EventLoopFuture<View> {
        var context = context
        do { try context = flattenContexts(context) }
        catch { return eventLoop.makeFailedFuture(error) }
        return renderer.render(template: template,
                               from: source,
                               context: context,
                               options: options)
                        .map { View(data: $0) }
    }
    
    static var entities: LeafEntities {
        get { LeafConfiguration.entities }
        set { LeafConfiguration.entities = newValue }
    }
}

// MARK: - Internal Properties & Methods

internal extension LeafEngine {
    typealias Context = LeafRenderer.Context
    typealias ContextStack = [Context]
    
    var storage: Storage? {
        get { req != nil ? req!.storage[Key.self] : app.storage[Key.self] }
        nonmutating set {
            if req != nil { req!.storage[Key.self] = newValue }
            else { app.storage[Key.self] = newValue }
        }
    }
    
    func flattenContexts(_ top: LeafRenderer.Context) throws -> LeafRenderer.Context {
        var stack: ContextStack = []
        app.storage[Key.self].map { stack.append($0.context) }
        req?.storage[Key.self].map { stack.append($0.context) }
        stack.append(top)
        
        guard stack.count > 1 else { return stack[0] }
        var flat: LeafRenderer.Context = stack[0]
        try stack[1..<stack.count].forEach { try flat.overlay($0) }
        return flat
    }
}
