NAME
====

`class Config::BINDish::AST::Block` - representation of a configuration block

DESCRIPTION
===========

Is [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md).

Does [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Parent.md) and [`Config::BINDish::AST::Decl`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Decl.md).

ATTRIBUTES
==========

### [`Config::BINDish::AST::Container`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Container.md) `$.name`

Block name.

### [`Config::BINDish::AST::Container`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Container.md) `$.class`

Block class.

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.flat`

A flat block doesn't allow multiple children of the same kind. In other words, for a flat block it is guaranteed that for the same named and classified blocks, or same options, there will always be only one child under the block's AST node.

For example:

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

The attribute is by default set either to the value in `$*CFG-FLAT-BLOCKS` or to *False*.

METHODS
=======

### `set-name(Config::BINDish::AST::Container:D $name)`

Sets block name. Returns block object itself.

### `set-class(Config::BINDish::AST::Container:D $class)`

Sets block class. Returns block object itself.

### `multi add(Config::BINDish::AST::Block:D $block)`

Add `$block` as a child.

### `multi add(Config::BINDish::AST::Option $option)`

Adds `$option` as a child.

### `flatten()`

Returns a flattened copy of the block.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

