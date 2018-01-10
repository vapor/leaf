import Async
import CodableKit

/// Converts encodable objects to TemplateData.
public final class TemplateDataEncoder {
    /// Create a new LeafEncoder.
    public init() {}

    /// Encode an encodable item to leaf data.
    public func encode(_ encodable: Encodable) throws -> TemplateData {
        let encoder = _TemplateDataEncoder()
        try encodable.encode(to: encoder)
        return encoder.partialData.data
    }
}

/// Internal leaf data encoder.
internal final class _TemplateDataEncoder: Encoder {
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    var partialData: PartialTemplateData
    var context: TemplateData {
        return partialData.data
    }

    init(partialData: PartialTemplateData = .init(), codingPath: [CodingKey] = []) {
        self.partialData = partialData
        self.codingPath = codingPath
        self.userInfo = [:]
    }

    /// See Encoder.container
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let keyed = TemplateDataKeyedEncoder<Key>(
            codingPath: codingPath,
            partialData: partialData
        )
        return KeyedEncodingContainer(keyed)
    }

    /// See Encoder.unkeyedContainer
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return TemplateDataUnkeyedEncoder(
            codingPath: codingPath,
            partialData: partialData
        )
    }

    /// See Encoder.singleValueContainer
    func singleValueContainer() -> SingleValueEncodingContainer {
        return TemplateDataSingleValueEncoder(
            codingPath: codingPath,
            partialData: partialData
        )
    }
}

/// MARK: Stream

extension _TemplateDataEncoder: StreamEncoder {
    func encodeStream<O>(_ stream: O) throws where O : OutputStream, O.Output == Encodable {
        let stream = stream.map(to: TemplateData.self) { encodable in
            return try TemplateDataEncoder().encode(encodable)
        }

        self.partialData.set(to: .stream(AnyOutputStream(stream)), at: codingPath)
    }
}

/// MARK: Future

extension _TemplateDataEncoder: FutureEncoder {
    func encodeFuture<E>(_ future: Future<E>) throws {
        let future = future.map(to: TemplateData.self) { any in
            guard let encodable = any as? Encodable else {
                fatalError("The expectation (\(E.self)) provided to template encoder for rendering was not Encodable")
            }

            let encoder = _TemplateDataEncoder(
                partialData: self.partialData,
                codingPath: self.codingPath
            )
            try encodable.encode(to: encoder)
            return encoder.context
        }

        self.partialData.set(to: .future(future), at: codingPath)
    }
}

