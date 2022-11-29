import LeafKit
import Algorithms

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
    let stringValue: String
    let intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }
    
    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    var description: String {
        "GenericCodingKey(\"\(self.stringValue)\"\(self.intValue.map { ", int: \($0)" } ?? ""))"
    }
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
    private final class EncoderImpl: Encoder, LeafEncodingResolvable, SingleValueEncodingContainer {
        /// See ``Encoder/userinfo``.
        let userInfo: [CodingUserInfoKey: Any]
        
        /// See ``Encoder/codingPath``.
        let codingPath: [CodingKey]
        
        /// This encoder's root stored value, if any has been encoded.
        var storage: LeafEncodingResolvable?
        
        /// An encoder can be resolved to the resolved value of its storage. This ability is used to support the
        /// the use of `superEncoder()` and `superEncoder(forKey:)`.
        var resolvedData: LeafData? { self.storage?.resolvedData }

        init(userInfo: [CodingUserInfoKey: Any] = [:], codingPath: [CodingKey]) {
            self.userInfo = userInfo
            self.codingPath = codingPath
        }
        
        convenience init(from encoder: EncoderImpl, withKey key: CodingKey?) {
            self.init(userInfo: encoder.userInfo, codingPath: encoder.codingPath + [key].compacted())
        }
        
        /// Need to expose the ability to access unwrapped keyed container to enable use of nested
        /// keyed containers (see the keyed and unkeyed containers).
        func rawContainer<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedContainerImpl<Key> {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }

            self.storage = KeyedContainerImpl<Key>(encoder: self)
            return self.storage as! KeyedContainerImpl<Key>
        }

        /// See ``Encoder/container(keyedBy:)``.
        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            .init(self.rawContainer(keyedBy: type))
        }

        /// See ``Encoder/unkeyedContainer()``.
        func unkeyedContainer() -> UnkeyedEncodingContainer {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }

            self.storage = UnkeyedContainerImpl(encoder: self)
            return self.storage as! UnkeyedContainerImpl
        }

        /// See ``Encoder/singleValueContainer()``.
        func singleValueContainer() -> SingleValueEncodingContainer {
            guard self.storage == nil else { fatalError("Can't encode to multiple containers at the same encoding level") }
            return self
        }

        /// See ``SingleValueEncodingContainer/encodeNil()``.
        func encodeNil() throws {}

        /// See ``SingleValueEncodingContainer/encode(_:)``.
        func encode<T>(_ value: T) throws where T: Encodable {
            self.storage = try self.encode(value, forKey: nil)
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
                let subencoder = Self.init(from: self, withKey: key)

                try value.encode(to: subencoder)
                return subencoder.storage?.resolvedData
            }
        }
    }

    private final class KeyedContainerImpl<Key>: KeyedEncodingContainerProtocol, LeafEncodingResolvable where Key: CodingKey {
        private weak var encoder: EncoderImpl!
        private var data: [String: LeafEncodingResolvable] = [:]
        private var nestedEncoderCaptures = [AnyObject]()
        
        /// See ``LeafEncodingResolvable/resolvedData``.
        var resolvedData: LeafData? { .dictionary(self.data.compactMapValues { $0.resolvedData }) }

        init(encoder: EncoderImpl) { self.encoder = encoder }

        /// See ``KeyedEncodingContainerProtocol/codingPath``.
        var codingPath: [CodingKey] { self.encoder.codingPath }

        /// See ``KeyedEncodingContainerProtocol/encodeNil()``.
        func encodeNil(forKey key: Key) throws {}

        /// See ``KeyedEncodingContainerProtocol/encode(_:forKey:)``.
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            guard let encodedValue = try self.encoder.encode(value, forKey: key) else { return }
            self.data[key.stringValue] = encodedValue
        }

        /// See ``KeyedEncodingContainerProtocol/nestedContainer(keyedBy:forKey:)``.
        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            let nestedEncoder = EncoderImpl(from: encoder, withKey: key)
            nestedEncoderCaptures.append(nestedEncoder)
            
            /// Use a subencoder to create a nested container so the coding paths are correctly maintained.
            /// Save the subcontainer in our data so it can be resolved later before returning it.
            return .init(self.insert(
                nestedEncoder.rawContainer(keyedBy: NestedKey.self),
                forKey: key,
                as: KeyedContainerImpl<NestedKey>.self
            ))
        }

        /// See ``KeyedEncodingContainerProtocol/nestedUnkeyedContainer(forKey:)``.
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            let nestedEncoder = EncoderImpl(from: encoder, withKey: key)
            nestedEncoderCaptures.append(nestedEncoder)
            
            return self.insert(
                nestedEncoder.unkeyedContainer() as! UnkeyedContainerImpl,
                forKey: key
            )
        }

        /// A super encoder is, in fact, just a subdecoder with delusions of grandeur and some rather haughty
        /// pretensions. (It's mostly Codable's fault anyway.)
        func superEncoder() -> Encoder {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            return self.insert(
                EncoderImpl(from: encoder, withKey: GenericCodingKey(stringValue: "super")),
                forKey: GenericCodingKey(stringValue: "super")
            )
        }

        /// See ``KeyedEncodingContainerProtocol/superEncoder(forKey:)``.
        func superEncoder(forKey key: Key) -> Encoder {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            return self.insert(EncoderImpl(from: encoder, withKey: key), forKey: key)
        }

        /// Helper for the encoding methods.
        private func insert<T>(_ value: LeafEncodingResolvable, forKey key: CodingKey, as: T.Type = T.self) -> T {
            self.data[key.stringValue] = value
            return value as! T
        }
    }
    
    private final class UnkeyedContainerImpl: UnkeyedEncodingContainer, LeafEncodingResolvable {
        private weak var encoder: EncoderImpl!
        private var data: [LeafEncodingResolvable] = []
        
        private var nestedEncoderCaptures = [AnyObject]()
        
        /// See ``LeafEncodingResolvable/resolvedData``.
        var resolvedData: LeafData? { .array(data.compactMap(\.resolvedData)) }
        
        /// See ``UnkeyedEncodingContainer/codingPath``.
        var codingPath: [CodingKey] { self.encoder.codingPath }

        /// See ``UnkeyedEncodingContainer/count``.
        var count: Int = 0

        init(encoder: EncoderImpl) { self.encoder = encoder }

        /// See ``UnkeyedEncodingContainer/encodeNil()``.
        func encodeNil() throws {}

        /// See ``UnkeyedEncodingContainer/encode(_:)``.
        func encode<T>(_ value: T) throws where T: Encodable {
            guard let encodedValue = try self.encoder.encode(value, forKey: self.nextCodingKey) else { return }
            
            self.data.append(encodedValue)
            self.count += 1
        }

        /// See ``UnkeyedEncodingContainer/nestedContainer(keyedBy:)``.
        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            let nestedEncoder = EncoderImpl(from: encoder, withKey: self.nextCodingKey)
            nestedEncoderCaptures.append(nestedEncoder)
            
            return .init(self.add(
                nestedEncoder.rawContainer(keyedBy: NestedKey.self),
                as: KeyedContainerImpl<NestedKey>.self
            ))
        }

        /// See ``UnkeyedEncodingContainer/nestedUnkeyedContainer()``.
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            let nestedEncoder = EncoderImpl(from: encoder, withKey: self.nextCodingKey)
            nestedEncoderCaptures.append(nestedEncoder)
            
            return self.add(nestedEncoder.unkeyedContainer() as! UnkeyedContainerImpl)
        }

        /// See ``UnkeyedEncodingContainer/superEncoder()``.
        func superEncoder() -> Encoder {
            guard let encoder = encoder else {
                fatalError("Encoder deallocated")
            }
            
            return self.add(EncoderImpl(from: encoder, withKey: self.nextCodingKey))
        }

        /// A `CodingKey` corresponding to the index that will be given to the next value added to the array.
        private var nextCodingKey: CodingKey { GenericCodingKey(intValue: self.count) }

        /// Helper for the encoding methods.
        private func add<T>(_ value: LeafEncodingResolvable, as: T.Type = T.self) -> T {
            self.data.append(value)
            self.count += 1
            return value as! T
        }
    }
}
