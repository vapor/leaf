class Stem {
    let workingDirectory: String
    var drivers: [String: InstructionDriver] = [
        "": _Variable(),
        "if": _If(),
        "else": _Else(),
        "loop": _Loop(),
        "uppercased": _Uppercased(),
        "include": _Include()
    ]

    init(workingDirectory: String = workDir) {
        self.workingDirectory = workingDirectory.finished(with: "/")
    }
}
