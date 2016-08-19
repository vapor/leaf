/*
 Potentially expose in future
 */
import Core
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
