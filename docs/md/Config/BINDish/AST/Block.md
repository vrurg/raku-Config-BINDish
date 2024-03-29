# CLASS

`class Config::BINDish::AST::Block` - representation of a configuration block

# DESCRIPTION

Is [`Config::BINDish::AST::Node`](Node.md).

Does [`Config::BINDish::AST::Blockish`](Blockish.md).

# ATTRIBUTES

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.flat`

A flat block doesn't allow multiple children of the same kind. In other words, for a flat block it is guaranteed that for the same named and classified blocks, or same options, there will always be only one child under the block's AST node.

For example:

``` 
foo "bar" { # A flat block
    opt1 "1";
    opt1 2; # This will override the above
    subblock "baz" {
        opt2 "first";
    }
    subblock "baz" {
        opt2 "second"; # :foo<bar> => :subblock<baz> => "opt2" will return "second"
    }
}
```

The attribute is by default set either to the value in `$*CFG-FLAT-BLOCKS` or to *False*.

# METHODS

### `keyword(Bool :$raw)`

Returns value payload of a child marked with *'block-type'* or *'keyword'* label. Returns the AST node itself with `:raw` argument.

### `name(Bool :$raw)`

Returns value payload of a child marked with *'block-name'* label. Returns the AST node itself with `:raw` argument.

### `class(Bool :$raw)`

Returns value payload of a child marked with *'block-class'* label. Returns the AST node itself with `:raw` argument.

### `multi add(Config::BINDish::AST::Block:D $block)`

Add `$block` as a child.

### `multi add(Config::BINDish::AST::Option $option)`

Adds `$option` as a child.

### `flatten()`

Returns a flattened copy of the block.

# SEE ALSO

  - item [`Config::BINDish`](../../BINDish.md)

  - item [`Config::BINDish::AST`](../AST.md)

  - [`README`](../../../../../README.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
