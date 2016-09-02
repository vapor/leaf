<p align="center"><img src="http://upload.wikimedia.org/wikipedia/commons/9/9d/Pear_Leaf.jpg" width="200"></img></p>

# Leaf

Welcome to Leaf. Leaf's goal is to be a simple templating language that can make generating views easier. There's a lot of great templating languages, use what's best for you, maybe that's leaf! The goals of leaf are as follows:

- Small set of strictly enforced rules
- Consistency
- Parser first mentality
- Extensibility.

# Syntax

Leaf syntax is based around a single token, in this case, the hashtag: `#`.


>It's important to note that _all_ hashtags will be parsed, there is no escaping. Use `#()` to render a plain `#`. `#()Leaf` => `#Leaf`. Or, for larger sections, use the `raw` tag. `#raw() { #Do #whatever #you #want #to #in #here!. }`

### Structure

Here we see all the components of a Leaf tag.

```leaf
#someTag(parameter.list, goes, "here") {
  This is an optional body here
}
```

#### Token

> The `#` token will define we're a tag

#### Name

>In above example, it would be `someTag`. While not strictly enforced, it is HIGHLY encouraged that users only use alphanumeric characters in names. This may be enforced in future versions.

#### Parameter List

> Var(parameter, list), Var(goes), Const("here")

#### Body

> This is an optional body here indicated w/ open and closed curly brackets.

### Using # in html with Leaf

If you need # to appear alone in your html, simply using `#()` will render as #. Alternatively, the raw tag is available for larger sections of code:

```leaf
#raw() {
   Do whatever w/ #'s here, this code
   won't be rendered as leaf document.
   It's a great place for things like Javascript or large HTML sections.
}
```

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

### Chaining

The double token, `##` indicates a chain. If the previous tag fails, this tag will be given an opportunity to run. It can be applied to any standard tag, for example, above we chain to else, but we could also chain to loops.

```
#ifEmpty(friends) {
    Try adding some friends!
} ##loop(friends, "friend") {
    <li> #(friend.name) </li>
}
```

## Custom Tags

Look at the existing tags for advanced scenarios, let's look at a basic example by creating `Index` together. This tag will take two arguments, an array, and an index to access.

```
class Index: BasicTag {
    let name = "index"

    func run(arguments: [Argument]) throws -> Node? {
        guard
            arguments.count == 2,
            let array = arguments[0].value?.nodeArray,
            let index = arguments[1].value?.int,
            index < array.count
            else { return nil }
        return array[index]
    }
}
```

Now, after creating our `Stem`, we can register the tag:

```
stem.register(Index())
```

And use it like so:

```
Hello, #index(friends, "0")!
```

We can also chain `else` to this like we did earlier if we want to check existence first:

```
#index(friends, "0") {
    Hello, #(self)!
} ##else() {
    Nobody's there!
}
```

# Inspiration

This library was inspired by:

- [Stencil](https://github.com/kylef/stencil)
- [Mustache](https://github.com/groue/GRMustache.swift)
- [Blade](https://laravel.com/docs/5.3/templates)
