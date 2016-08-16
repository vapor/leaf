Welcome to \(name)

# Variables

Syntax: `\(` + `<#variable-name#>` + `)`.

For example:

```
[
  "name": "Jen T. Person"
]
```

with:

```html
Hello, \(name)!
```

```html
@var name { Hello, \(self) }
```

```html
Hello, @var(name)!

Your friends are @loop(friends) { @(name) }
```

```html
Hello, @(name)!

Your friends are @loop(friends) { @(name), and }

Escape @join(friends)\ { these will show up }
```

```html
Hello, @(name)!

Your friends are @loop(friends) { @(name), aged @(age) }
```

```html
// context is list
<h1>@(list-name)</h1>

You have @count(items, "unfinished") left to do.


@loop(items.sorted().filteredBy("name")) {
  <li>@(name)<\li>
}
@loop(items.sorted()) {
  <li>@(name)<\li>
}

```

If a `{ }` body is trailing, then that body will be rendered using the result of the arguments handle as context.

For example

@loop(friends) { // friends is context here }

```
// received array of strings
@join(self, ", ")
```

Will render: `Hello, Jen T. Person!`

@uppercase name { \(self) }

// TODO:
// If token is followed directly by `(`, it will parse out as files
```objc
@var(name)
=>
@var name { \(self) }
```

# Comands

Syntax: `@` + `<#command-name#>` + `<#arguments#>` + `{` + `<#input`

@loop friends {
  <li>\(name)</li>
} @ifnull {

}

@if age|greaterThan:25 {
  You can rent a car
} @else {

}

@forEach self {

}

@key arguments  { }
@loop forEach { value in
  <li>$0<li>
}

@if


```html
Hello, \(name|uppercase)!

<h3>My Friends</h3>
@forEach \(friends) {
  <li>$0</li>
}

@if \(age|greaterThan:25) {

} @elseif \(age|greaterThan:18) {

} @else {

}
```
