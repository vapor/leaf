<p align="center"><img src="http://upload.wikimedia.org/wikipedia/commons/9/9d/Pear_Leaf.jpg" width="200"></img></p>

# Leaf

Welcome to Leaf. Leaf's goal is to be a simple templating language that can make generating views easier. There's a lot of great templating languages, use what's best for you, maybe that's leaf! The goals of leaf are as follows:

- Small set of strictly enforced rules
- Consistency
- Parser first mentality
- Extensibility.

# Syntax

Leaf syntax is based around a single token, in this case, the caret: `^`.


>It's important to note that _all_ carets will be parsed, there is no escaping. Use `^()` to render a plain `^`. `4 ^() 5` => `4 ^ 5`

### Structure

Here we see all the components of a Leaf tag.

```leaf
^name(parameter.list, goes, "here") {
  This is an optional body here
}
```

#### Token

> ^

#### Name

> name

#### Parameter List

> Var(parameter, list), Var(goes), Const("here")

#### Body

> This is an optional body here

### 1. Token

The first thing we see is the `^` token. This indicates the start of a tag.

All tags MUST be terminated with an open parenthesis, even if there is no parameters. For example, `^empty()`, NOT ~~`^empty`~~

### 2. Name

All tag's MUST have a name. The name will be considered any string in between the token, `^`, and `(`

##### Examples

1. `^()` => `""`
2. `^someName()` => `"someName"`
3. `^number1()` => `"number1"`

### 3. Parameter List

The parameter list is signified by the open parenthesis and terminated by the closing parenthesis. There are two types of parameters in leaf. It is a comma separated list of indeterminate length.

##### 1. Context Variable

A context variable is something that will be pulled from the context during rendering and will be different each time Leaf generates the view. There is no special indication.

You can also use `.` to indicate paths when displaying context. For example, given:

```
[
  "name": "World",
  "friends": [
    [ "name" : "Venus" ],
    [ "name" : "Mercury" ],
    [ "name" : "Neptune" ],
  ]
]
```

And the following Leaf.

```
Hello, ^(friends.1.name)!
```

We would render:

```
Hello, Mercury!
```

##### 1. Static Constant

Static constants are parameters that will never change each time leaf renders a view. They are declared by using surrounding quotations.

```
Hello, ^("World")!
```

In the above example, no matter what I pass into the context, it will render as `Hello, World!` because it is a constant. Static constants are most often used for specifying behavior about a tag.

### 4. Body

Sometimes tags require a body, sometimes they will not. A body is generally scoped further into the context in some way, and can be used to control the flow and contents of a layout.

```leaf
^if(is21) {
  <h1>Welcome to the Beer Barn!</h1>
}
```




#### 1.

Context:

```
[
  "name": "World"
]
```

Leaf:

```
Hello, ^(name)!
```

Render:

```
Hello, World!
```

#### 2.

Context:

```
[
  "name": "World",
  "friend": [
    [ "name" : "Mars" ]
  ]
]
```

Leaf:

```
Hello, ^(friend.name)!
```

Render:

```
Hello, Mars!
```

#### 3.

Context:

```
[
  "name": "World",
  "friends": [
    [ "name" : "Venus" ],
    [ "name" : "Mercury" ],
    [ "name" : "Neptune" ],
  ]
]
```

Leaf:

```
Hello, ^(friends.1.name)!
```

Render:

```
Hello, Mercury!
```



> While not strictly enforced, it is HIGHLY encouraged that users only use alphanumeric characters in names. This may be enforced in future versions.

// TODO:

> This is a low sugar templating language. Some things might not be ideal. The goal is to have flexibility, but first we must be stable. At that point, we will add sugar.

### Using # in html with Leaf

If you need # to appear alone in your html, simply using `#()` will render as #

# Examples

### Variable

Variables are added w/ just a number sign.

```leaf
Hello, #(name)!
```

### Loop

Loop a variable

```leaf
#loop(friends, "friend") {
  Hello, #(friend.name)!
}
```

### If - Else

```leaf
#if(entering) {
  Hello, there!
} ##if(leaving) {
  Goodbye!
} ##else() {
  I've been here the whole time.
}
```

// TODO:

## Custom Tags



# Inspiration

This library was inspired by:

- [Stencil](https://github.com/kylef/stencil)
- [Mustache](https://github.com/groue/GRMustache.swift)
