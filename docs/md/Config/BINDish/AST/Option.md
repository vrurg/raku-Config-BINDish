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

### `keyword()`

Returns a [`Config::BINDish::AST::Container`](Container.md) child labeled with *"keyword"* label which represents the value used to declare the option.

### `name()`

An alias to the `keyword()` method.

### `value()`

Returns a [`Config::BINDish::AST::Container`](Container.md) child marked with *"option-value"* label which represents option's value.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::AST`](../AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

