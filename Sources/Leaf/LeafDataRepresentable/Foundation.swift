import Foundation
import Vapor

extension URL: LeafDataRepresentable {
    public static var leafDataType: LeafDataType? { .dictionary }
    public var leafData: LeafData { (try? resourceValues(forKeys: .init(LFMIndexing.keys))).leafData }
}

extension URLResourceValues: LeafDataRepresentable {
    public static var leafDataType: LeafDataType? { .dictionary }
    public var leafData: LeafData {.dictionary([
        "name": name,
        "isApplication": isApplication,
        "isDirectory": isDirectory,
        "isRegularFile": isRegularFile,
        "isHidden": isHidden,
        "isSymbolicLink": isSymbolicLink,
        "fileSize": fileSize,
        "creationDate": creationDate,
        "contentModificationDate": contentModificationDate,
        "mimeType": canonicalPath.map {HTTPMediaType.fileExtension($0.fileExt) ?? .plainText}
    ])}
}
