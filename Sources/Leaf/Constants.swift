@_exported import Core
@_exported import Node

/*
    Potentially expose in future
*/
internal let TOKEN: Byte = "*".bytes.first!
internal let SUFFIX = ".leaf"

/**
    Automatically added to newly created stems
*/
public var defaultTags: [String: Tag] = [
    "": Variable(),
    "if": If(),
    "else": Else(),
    "loop": Loop(),
    "uppercased": Uppercased(),
    "embed": Embed(),
    "index": Index(),
]
