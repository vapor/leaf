<p align="center"><img src="http://upload.wikimedia.org/wikipedia/commons/9/9d/Pear_Leaf.jpg" width="200"></img></p>

# Leaf

Welcome to Leaf. Leaf's goal is to be a simple templating language that can make generating views easier.

### Why Another

There's a lot of great templating languages, the goals of leaf are as follows:

- Small set of strict rules
- Easy to interpret from a parsing perspective
- All behavior added as extensions to the core

# Syntax

Leaf syntax is based around a single token, in this case, the hashtag: `#`.

// TODO:

> This is a low sugar templating language. Some things might not be ideal. The goal is to have flexibility, but first we must be stable. At that point, we will add sugar.

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
