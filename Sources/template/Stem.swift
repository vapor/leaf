let defaultTags: [String: Tag] = [
    "": _Variable(),
    "if": _If(),
    "else": _Else(),
    "loop": _Loop(),
    "uppercased": _Uppercased(),
    "include": _Include()
]

class Stem {
    let workingDirectory: String
    var tags: [String: Tag] = defaultTags

    init(workingDirectory: String = workDir) {
        self.workingDirectory = workingDirectory.finished(with: "/")
    }
}
