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
Hello, \(name)!
```
Will render: `Hello, Jen T. Person!`

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
