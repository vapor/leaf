final class _Variable: Tag {
    let name = "" // empty name, ie: @(variable)

    func run(stem: Stem, filler: Scope, tagTemplate: TagTemplate, arguments: [Argument]) throws -> Any? {
        /*
         Currently ALL '@' signs are interpreted as tagTemplates.  This means to escape in

         name@email.com

         We'd have to do:

         name@("@")email.com

         or more pretty

         contact-email@("@email.com")

         By having this uncommented, we could allow

         name@()email.com
         */
        if arguments.isEmpty { return [TOKEN].string } // temporary escaping mechanism?
        guard arguments.count == 1 else { throw "invalid var argument" }
        let argument = arguments[0]
        switch argument {
        case let .constant(value: value):
            return value
        case let .variable(key: _, value: value):
            return value
        }
    }
}
