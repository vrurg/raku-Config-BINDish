CLASS
=====

`class Config::BINDish::AST::Option` - configuration option representation

DESCRIPTION
===========

Is [`Config::BINDish::AST::Node`](Node.md).

ATTRIBUTES
==========

### `$.id`

Unique ID of an option object. See [`Config::BINDish::Grammar Pre-declaration`](../Grammar.md#Pre-declaration) section.

METHODS
=======

### `keyword(Bool :$raw)`

Returns value payload of a child node labeled with *"keyword"* label. Returns the AST node itself with `:raw` argument.

### `name(Bool :$raw)`

An alias to the `keyword()` method.

### `value(Bool :$raw)`

Returns value payload of a child marked with *"option-value"*. Returns the AST node itself with `:raw` argument.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::AST`](../AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

