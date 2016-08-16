import Core

let _ = "Hello, \\(variable)!"


// "blah blah @forEach friends { Hello, \(name)! }"
// =>
// Hello, Joe! Hello, Jen!
let forLoop = "blah blah @forEach friends { Hello, \\(name)! }"

let context: [String: Any] = [
    "name": "Logan",
    "friends": [
        [
            "name": "Joe"
        ],
        [
            "name": "Jen"
        ]
    ]
]

protocol Context {}
typealias Loader = (arguments: [Context]) -> String


func doStuff(input: String) {
    let buffer = StaticDataBuffer(bytes: input.bytes)

    var iterator = input.bytes.makeIterator()
    while let n = iterator.next() {
    }
}

class
