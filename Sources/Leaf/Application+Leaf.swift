import LeafKit
import Vapor

extension Application.Views.Provider {
    public static var leaf: Self {
        .init {
            $0.views.use {
                $0.leaf.renderer
            }
        }
    }
}

extension Application {
    public var leaf: Leaf {
        .init(application: self)
    }

    public struct Leaf {
        public let application: Application

        public var renderer: LeafRenderer {
            var userInfo = self.userInfo
            userInfo["application"] = self.application

            var cache = self.cache
            if self.application.environment == .development {
                cache.isEnabled = false
            }
            return .init(
                configuration: self.configuration,
                tags: self.tags,
                cache: cache,
                sources: self.sources,
                eventLoop: self.application.eventLoopGroup.next(),
                userInfo: userInfo
            )
        }

        public var configuration: LeafConfiguration {
            get {
                self.storage.configuration ??
                LeafConfiguration(rootDirectory: self.application.directory.viewsDirectory)
            }
            nonmutating set {
                self.storage.configuration = newValue
            }
        }

        public var tags: [String: any LeafTag] {
            get {
                self.storage.tags
            }
            nonmutating set {
                self.storage.tags = newValue
            }
        }

        public var sources: LeafSources {
            get {
                self.storage.sources ?? LeafSources.singleSource(NIOLeafFiles(
                    fileio: self.application.fileio,
                    limits: .default,
                    sandboxDirectory: self.configuration.rootDirectory,
                    viewDirectory: self.configuration.rootDirectory
                ))
            }
            nonmutating set {
                self.storage.sources = newValue
            }
        }

        public var cache: any LeafCache {
            get {
                self.storage.cache
            }
            nonmutating set {
                self.storage.cache = newValue
            }
        }

        public var userInfo: [AnyHashable: Any] {
            get {
                self.storage.userInfo
            }
            nonmutating set {
                self.storage.userInfo = newValue
            }
        }

        var storage: Storage {
            if let existing = self.application.storage[Key.self] {
                return existing
            } else {
                let new = Storage()
                self.application.storage[Key.self] = new
                return new
            }
        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        final class Storage: @unchecked Sendable {
            var cache: any LeafCache
            var configuration: LeafConfiguration?
            var sources: LeafSources?
            var tags: [String: any LeafTag]
            var userInfo: [AnyHashable: Any]

            init() {
                self.cache = DefaultLeafCache()
                self.tags = LeafKit.defaultTags
                self.userInfo = [:]
            }
        }
    }
}

extension LeafContext {
    public var application: Application? {
        self.userInfo["application"] as? Application
    }
}
