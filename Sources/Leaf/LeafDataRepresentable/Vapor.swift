import Vapor

extension HTTPMediaType: LeafDataRepresentable {
    public static var leafDataType: LeafDataType? { .dictionary }
    public var leafData: LeafData { .dictionary([
        "type": type,
        "subType": subType,
        "parameters": parameters,
        "serialized": serialize(),
    ]) }
}
