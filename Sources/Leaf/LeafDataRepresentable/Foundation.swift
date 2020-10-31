import Foundation
import Vapor

extension URL {
    var _leafData: LeafData {
        var values = (try? resourceValues(forKeys: .init(LFMIndexing.keys)))?._leafData ?? [:]
        values["name"] = lastPathComponent
        values["absolutePath"] = absoluteString
        values["pathComponents"] = pathComponents
        values["mimeType"] = HTTPMediaType.fileExtension(pathExtension) ?? .plainText
        return .dictionary(values)
    }
}

extension URLResourceValues {
    var _leafData: [String: LeafDataRepresentable] {[
        "isApplication": isApplication,
        "isDirectory": isDirectory,
        "isRegularFile": isRegularFile,
        "isHidden": isHidden,
        "isSymbolicLink": isSymbolicLink,
        "fileSize": fileSize,
        "creationDate": creationDate,
        "contentModificationDate": contentModificationDate,
    ]}
}
