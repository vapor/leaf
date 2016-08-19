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
    "include": Include(),

    // HTML Tags
    "html": HTML(),
    "body": Body(),
    "div": Div(),
    "head": Head(),
    "h1": H1() // make '1' dynamic 'h1': H(size: 1), 'h2': H(size: 2)
]

/*
     // TODO: GLOBAL
     - Filters/Modifiers are supported longform, consider implementing short form -> Possibly compile out to longform
         `@(foo.bar()` == `@bar(foo)`
         `@(foo.bar().waa())` == `@bar(foo) { @waa(self) }`
     - Extendible Leafs
     - Allow no argument tags to terminate with a space, ie: @h1 {` or `@date`
     - HTML Tags, a la @h1() { }
     - Dynamic Tag w/ (Any?) throws? -> Any?
*/
