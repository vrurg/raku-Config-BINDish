CLASS
=====

`class Config::BINDish::AST::Option` - configuration option representation

DESCRIPTION
===========

Is [`Config::BINDish::AST::Node`](Node.md).

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

