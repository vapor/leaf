import LeafKit

internal final class LeafEncoder {
    func encode<E>(_ encodable: E) throws -> [String: LeafData]
        where E: Encodable
    {
        let encoder = _Encoder(codingPath: [])
        try encodable.encode(to: encoder)
        let data = encoder.container!.data!.resolve()
        guard let dictionary = data.dictionary else { fatalError() }
        return dictionary
    }
}

/// MARK: Private

protocol _Container {
    var data: _Data? { get }
}

enum _Data {
    case container(_Container)
    case data(LeafData)

    func resolve() -> LeafData {
        switch self {
        case .container(let container):
            return container.data!.resolve()
        case .data(let data):
            return data
        }
    }
}

/// Private `Encoder`.
private final class _Encoder: Encoder {
    var userInfo: [CodingUserInfoKey: Any] { [:] }
    let codingPath: [CodingKey]
    var container: _Container?

    /// Creates a new form url-encoded encoder
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.container = nil
    }

    /// See `Encoder`
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
        where Key: CodingKey
    {
        let container = KeyedContainer<Key>(codingPath: codingPath)
        self.container = container
        return .init(container)
    }

    /// See `Encoder`
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer(codingPath: codingPath)
        self.container = container
        return container
    }

    /// See `Encoder`
    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueContainer(codingPath: codingPath)
        self.container = container
        return container
    }
}

/// Private `SingleValueEncodingContainer`.
private final class SingleValueContainer: SingleValueEncodingContainer, _Container {
    /// See `SingleValueEncodingContainer`
    var codingPath: [CodingKey]

    /// The data being encoded
    var data: _Data?

    /// Creates a new single value encoder
    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }

    /// See `SingleValueEncodingContainer`
    func encodeNil() throws {
        // skip
    }

    /// See `SingleValueEncodingContainer`
    func encode<T>(_ value: T) throws where T: Encodable {
        if let leafRepresentable = value as? LeafDataRepresentable {
            self.data = .data(leafRepresentable.leafData)
        } else {
            let encoder = _Encoder(codingPath: self.codingPath)
            try value.encode(to: encoder)
            self.data = encoder.container!.data
        }
    }
}


/// Private `KeyedEncodingContainerProtocol`.
private final class KeyedContainer<Key>: KeyedEncodingContainerProtocol, _Container
    where Key: CodingKey
{
    var codingPath: [CodingKey]

    var data: _Data? {
        return .data(.dictionary(self.dictionary.mapValues { $0.resolve() }))
    }

    var dictionary: [String: _Data]

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.dictionary = [:]
    }

    /// See `KeyedEncodingContainerProtocol`
    func encodeNil(forKey key: Key) throws {
        // skip
    }

    /// See `KeyedEncodingContainerProtocol`
    func encode<T>(_ value: T, forKey key: Key) throws
        where T : Encodable
    {
        if let leafRepresentable = value as? LeafDataRepresentable {
            self.dictionary[key.stringValue] = .data(leafRepresentable.leafData)
        } else {
            let encoder = _Encoder(codingPath: codingPath + [key])
            try value.encode(to: encoder)
            self.dictionary[key.stringValue] = encoder.container!.data
        }
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = KeyedContainer<NestedKey>(codingPath: self.codingPath + [key])
        self.dictionary[key.stringValue] = .container(container)
        return .init(container)
    }

    /// See `KeyedEncodingContainerProtocol`
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer(codingPath: self.codingPath + [key])
        self.dictionary[key.stringValue] = .container(container)
        return container
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder() -> Encoder {
        fatalError()
    }

    /// See `KeyedEncodingContainerProtocol`
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
}

/// Private `UnkeyedEncodingContainer`.
private final class UnkeyedContainer: UnkeyedEncodingContainer, _Container {
    var codingPath: [CodingKey]
    var count: Int
    var data: _Data? {
        return .data(.array(self.array.map { $0.resolve() }))
    }
    var array: [_Data]

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.count = 0
        self.array = []
    }

    func encodeNil() throws {
        // skip
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        defer { self.count += 1 }
        if let leafRepresentable = value as? LeafDataRepresentable {
            self.array.append(.data(leafRepresentable.leafData))
        } else {
            let encoder = _Encoder(codingPath: codingPath)
            try value.encode(to: encoder)
            self.array.append(encoder.container!.data!)
        }
    }

    /// See UnkeyedEncodingContainer.nestedContainer
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        defer { self.count += 1 }
        let container = KeyedContainer<NestedKey>(codingPath: self.codingPath)
        self.array.append(.container(container))
        return .init(container)
    }

    /// See UnkeyedEncodingContainer.nestedUnkeyedContainer
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        defer { self.count += 1 }
        let container = UnkeyedContainer(codingPath: self.codingPath)
        self.array.append(.container(container))
        return container
    }

    /// See UnkeyedEncodingContainer.superEncoder
    func superEncoder() -> Encoder {
        fatalError()
    }
}

private extension EncodingError {
    static func invalidValue(_ value: Any, at path: [CodingKey]) -> EncodingError {
        let pathString = path.map { $0.stringValue }.joined(separator: ".")
        let context = EncodingError.Context(
            codingPath: path,
            debugDescription: "Invalid value at '\(pathString)': \(value)"
        )
        return Swift.EncodingError.invalidValue(value, context)
    }
}
