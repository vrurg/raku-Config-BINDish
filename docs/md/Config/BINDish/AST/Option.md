CLASS
=====

`class Config::BINDish::AST::Option` - configuration option representation

DESCRIPTION
===========

Is [`Config::BINDish::AST::Node`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Node.md).

METHODS
=======



### `keyword()`

Returns a [`Config::BINDish::AST::Container`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Container.md) child labeled with *"keyword"* label which represents the value used to declare the option.

### `name()`

An alias to the `keyword()` method.

### `value()`

Returns a [`Config::BINDish::AST::Container`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Container.md) child marked with *"option-value"* label which represents option's value.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

