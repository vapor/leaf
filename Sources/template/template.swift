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
import Core
import Foundation

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

func loadLeaf(named name: String) throws -> Leaf {
    let stem = Stem()
    let template = try stem.loadLeaf(named: name)
    return template
}

func load(path: String) throws -> Bytes {
    guard let data = NSData(contentsOfFile: path) else {
        throw "unable to load bytes"
    }
    var bytes = Bytes(repeating: 0, count: data.length)
    data.getBytes(&bytes, length: bytes.count)
    return bytes
}


// TODO: Should optional be renderable, and render underlying?
protocol Renderable {
    func rendered() throws -> Bytes
}
