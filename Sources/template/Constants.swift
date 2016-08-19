@_exported import Core

/*
    Potentially expose in future
*/
internal let TOKEN: Byte = .numberSign
internal let SUFFIX = ".leaf"

public let defaultTags: [String: Tag] = [
    "": Variable(),
    "if": If(),
    "else": Else(),
    "loop": Loop(),
    "uppercased": Uppercased(),
    "include": Include()
]
