import LeafKit

internal struct LeafEncoder {
    /// Use `Codable` to convert an (almost) arbitrary encodable type to a dictionary of key/``LeafData`` pairs
    /// for use as a rendering context. The type's encoded form must have a dictionary (keyed container) at its
    /// top level; it may not be an array or scalar value.
    static func encode<E>(_ encodable: E) throws -> [String: LeafData] where E: Encodable {
        let encoder = EncoderImpl(codingPath: [])
        try encodable.encode(to: encoder)
        
        // If the context encoded nothing at all, yield an empty dictionary.
        let data = encoder.storage?.resolvedData ?? .dictionary([:])
        
        // Unfortunately we have to delay this check until this point thanks to `Encoder` ever so helpfully not
        // declaring most of its methods as throwing.
        guard let dictionary = data.dictionary else {
            throw LeafError(.illegalAccess("Leaf contexts must be dictionaries or structure types; arrays and scalar values are not permitted."))
        }
        
        return dictionary
    }
}

// MARK: - Private

/// One of these is always necessary when implementing an unkeyed container, and needed quite often for most
/// other things in Codable. Sure would be nice if the stdlib had one instead of there being 1000-odd versions
/// floating around various dependencies.
fileprivate struct GenericCodingKey: CodingKey, Hashable {
    let stringValue: String, intValue: Int?
    init(stringValue: String) { (self.stringValue, self.intValue) = (stringValue, Int(stringValue)) }
    init(intValue: Int) { (self.stringValue, self.intValue) = ("\(intValue)", intValue) }
    var description: String { "GenericCodingKey(\"\(self.stringValue)\"\(self.intValue.map { ", int: \($0)" } ?? ""))" }
}

/// Helper protocol allowing a single existential representation for all of the possible nested storage patterns
/// that show up during encoding.
fileprivate protocol LeafEncodingResolvable {
    var resolvedData: LeafData? { get }
}

/// A ``LeafData`` value always resolves to itself.
extension LeafData: LeafEncodingResolvable {
    var resolvedData: LeafData? { self }
}

extension LeafEncoder {
    /// The ``Encoder`` conformer.
    private final class EncoderImpl: Encoder, LeafEncodingResolvable {
        var userInfo: [CodingUserInfoKey: Any]
        let codingPath: [CodingKey]
        var storage: LeafEncodingResolvable?
        
        /// An encoder can be resolved to the resolved value of its storage. This ability is used to support the
        /// the use of `superEncoder()` and `superEncoder(forKey:)`.
        var resolvedData: LeafData? { self.storage?.resolvedData }

        init(userInfo: [CodingUserInfoKey: Any] = [:], codingPath: [CodingKey]) {
            self.userInfo = userInfo
            self.codingPath = codingPath
        }
        
        convenience init(subdecoding encoder: EncoderImpl, withKey key: CodingKey?) {
            self.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath + [key].compacted())
        }
        
        /// Need to expose the ability to access unwrapped keyed container to enable use of nested
        /// keyed containers (see the keyed and unkeyed containers).
        func rawContainer<Key: CodingKey>(keyedBy type: Key.Type) -> EncoderKeyedContainerImpl<Key> {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }
            self.storage = EncoderKeyedContainerImpl<Key>(encoder: self)
            return self.storage as! EncoderKeyedContainerImpl<Key>
        }

        /// See ``Encoder/container(keyedBy:)``.
        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            .init(self.rawContainer(keyedBy: type))
        }

        /// See ``Encoder/unkeyedContainer()``.
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }
            self.storage = EncoderUnkeyedContainerImpl(encoder: self)
            return self.storage as! EncoderUnkeyedContainerImpl
        }

        /// See ``Encoder/singleValueContainer()``.
        func singleValueContainer() -> SingleValueEncodingContainer {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }
            self.storage = EncoderValueContainerImpl(encoder: self)
            return self.storage as! EncoderValueContainerImpl
        }
        
        /// Encode an arbitrary encodable input, optionally deepening the current coding path with a
        /// given key during encoding, and return it as a resolvable item.
        func encode<T>(_ value: T, forKey key: CodingKey?) throws -> LeafEncodingResolvable? where T: Encodable {
            if let leafRepresentable = value as? LeafDataRepresentable {
                /// Shortcut through ``LeafDataRepresentable`` if `T` conforms to it.
                return leafRepresentable.leafData
            } else {
                /// Otherwise, route encoding through a new subdecoder based on self, with an appropriate
                /// coding path. This is the central recursion point of the entire Codable setup.
                let subencoder = Self.init(subdecoding: self, withKey: key)
                try value.encode(to: subencoder)
                return subencoder.storage?.resolvedData
            }
        }
    }

    private final class EncoderValueContainerImpl: SingleValueEncodingContainer, LeafEncodingResolvable {
        let encoder: EncoderImpl
        var resolvedData: LeafData?

        /// See ``SingleValueEncodingContainer/codingPath``.
        var codingPath: [CodingKey] { self.encoder.codingPath }
        
        init(encoder: EncoderImpl) { self.encoder = encoder }

        /// See ``SingleValueEncodingContainer/encodeNil()``.
        func encodeNil() throws {}

        /// See ``SingleValueEncodingContainer/encode(_:)``.
        func encode<T>(_ value: T) throws where T: Encodable {
            self.resolvedData = try self.encoder.encode(value, forKey: nil)?.resolvedData
        }
    }

    private final class EncoderKeyedContainerImpl<Key>: KeyedEncodingContainerProtocol, LeafEncodingResolvable where Key: CodingKey {
        let encoder: EncoderImpl
        var data: [String: LeafEncodingResolvable] = [:]
        var resolvedData: LeafData? { .dictionary(self.data.compactMapValues { $0.resolvedData }) }

        /// See ``KeyedEncodingContainerProtocol/codingPath``.
        var codingPath: [CodingKey] { self.encoder.codingPath }

        init(encoder: EncoderImpl) { self.encoder = encoder }

        func insert<T>(_ value: LeafEncodingResolvable, forKey key: CodingKey, as: T.Type = T.self) -> T {
            self.data[key.stringValue] = value
            return value as! T
        }

        /// See ``KeyedEncodingContainerProtocol/encodeNil()``.
        func encodeNil(forKey key: Key) throws {}

        /// See ``KeyedEncodingContainerProtocol/encode(_:forKey:)``.
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            guard let encodedValue = try self.encoder.encode(value, forKey: key) else { return }
            self.data[key.stringValue] = encodedValue
        }

        /// See ``KeyedEncodingContainerProtocol/nestedContainer(keyedBy:forKey:)``.
        func nestedContainer<NK>(keyedBy keyType: NK.Type, forKey key: Key) -> KeyedEncodingContainer<NK> where NK: CodingKey {
            /// Use a subencoder to create a nested container so the coding paths are correctly maintained.
            /// Save the subcontainer in our data so it can be resolved later before returning it.
            .init(self.insert(EncoderImpl(subdecoding: self.encoder, withKey: key).rawContainer(keyedBy: NK.self), forKey: key, as: EncoderKeyedContainerImpl<NK>.self))
        }

        /// See ``KeyedEncodingContainerProtocol/nestedUnkeyedContainer(forKey:)``.
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            self.insert((EncoderImpl(subdecoding: self.encoder, withKey: key).unkeyedContainer() as! EncoderUnkeyedContainerImpl), forKey: key)
        }

        /// A super encoder is, in fact, just a subdecoder with delusions of grandeur and some rather haughty
        /// pretensions. (It's mostly Codable's fault anyway.)
        func superEncoder() -> Encoder {
            self.insert(EncoderImpl(subdecoding: self.encoder, withKey: GenericCodingKey(stringValue: "super")), forKey: GenericCodingKey(stringValue: "super"))
        }

        /// See ``KeyedEncodingContainerProtocol/superEncoder(forKey:)``.
        func superEncoder(forKey key: Key) -> Encoder { self.insert(EncoderImpl(subdecoding: self.encoder, withKey: key), forKey: key) }
    }
    
    private final class EncoderUnkeyedContainerImpl: UnkeyedEncodingContainer, LeafEncodingResolvable {
        let encoder: EncoderImpl
        var data: [LeafEncodingResolvable] = []
        var nextCodingKey: CodingKey { GenericCodingKey(intValue: self.count) }
        var resolvedData: LeafData? { .array(data.compactMap(\.resolvedData)) }
        
        /// See ``UnkeyedEncodingContainer/codingPath``.
        var codingPath: [CodingKey] { self.encoder.codingPath }

        /// See ``UnkeyedEncodingContainer/count``.
        var count: Int = 0

        init(encoder: EncoderImpl) { self.encoder = encoder }

        func add<T>(_ value: LeafEncodingResolvable, as: T.Type = T.self) -> T {
            self.data.append(value)
            self.count += 1
            return value as! T
        }        

        /// See ``UnkeyedEncodingContainer/encodeNil()``.
        func encodeNil() throws {}

        /// See ``UnkeyedEncodingContainer/encode(_:)``.
        func encode<T>(_ value: T) throws where T: Encodable {
            guard let encodedValue = try self.encoder.encode(value, forKey: self.nextCodingKey) else { return }
            self.data.append(encodedValue)
            self.count += 1
        }

        /// See ``UnkeyedEncodingContainer/nestedContainer(keyedBy:)``.
        func nestedContainer<NK>(keyedBy keyType: NK.Type) -> KeyedEncodingContainer<NK> where NK: CodingKey {
            .init(self.add(EncoderImpl(subdecoding: self.encoder, withKey: self.nextCodingKey).rawContainer(keyedBy: NK.self), as: EncoderKeyedContainerImpl<NK>.self))
        }

        /// See ``UnkeyedEncodingContainer/nestedUnkeyedContainer()``.
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            self.add(EncoderImpl(subdecoding: self.encoder, withKey: self.nextCodingKey).unkeyedContainer() as! EncoderUnkeyedContainerImpl)
        }

        /// See ``UnkeyedEncodingContainer/superEncoder()``.
        func superEncoder() -> Encoder {
            self.add(EncoderImpl(subdecoding: self.encoder, withKey: self.nextCodingKey))
        }
    }
}
