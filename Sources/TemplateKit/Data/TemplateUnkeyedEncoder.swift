import CodableKit

internal final class TemplateDataUnkeyedEncoder: UnkeyedEncodingContainer {
    var count: Int
    var codingPath: [CodingKey]
    var partialData: PartialTemplateData

    var index: CodingKey {
        defer { count += 1 }
        return BasicKey(count)
    }

    init(codingPath: [CodingKey], partialData: PartialTemplateData) {
        self.codingPath = codingPath
        self.partialData = partialData
        self.count = 0
    }

    func encodeNil() throws {
        partialData.set(to: .null, at: codingPath + [index])
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey
    {
        let container = TemplateDataKeyedEncoder<NestedKey>(codingPath: codingPath + [index], partialData: partialData)
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return TemplateDataUnkeyedEncoder(codingPath: codingPath + [index], partialData: partialData)
    }

    func superEncoder() -> Encoder {
        return _TemplateDataEncoder(partialData: partialData, codingPath: codingPath + [index])
    }

    func encode(_ value: Bool) throws {
        partialData.set(to: .bool(value), at: codingPath + [index])
    }

    func encode(_ value: Int) throws {
        partialData.set(to: .int(value), at: codingPath + [index])
    }

    func encode(_ value: Double) throws {
        partialData.set(to: .double(value), at: codingPath + [index])
    }

    func encode(_ value: String) throws {
        partialData.set(to: .string(value), at: codingPath + [index])
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        let encoder = _TemplateDataEncoder(partialData: partialData, codingPath: codingPath + [index])
        try value.encode(to: encoder)
    }
}
