NAME
====

`role Config::BINDish::AST::Container` - common declarations for any kind of value containers

DESCRIPTION
===========

This role defines the interface and implementation of a container which is characterized by the value it contains and a type name associated with the value.

ATTRIBUTES
==========

### [`Mu`](https://docs.raku.org/type/Mu) `$.payload`

The actual value.

This attribute `handles` all stadndard coercion methods found on [`Match`](https://docs.raku.org/type/Match) and [`Str`](https://docs.raku.org/type/Str) classes. So, it is possible to coerce a container like this:

    my Int(Config::BINDish::AST::Container:D) $some-count = $container;

or even easier:

    my Int $some-count = Int($container);

### [`Str:D`](https://docs.raku.org/type/Str) `$.type-name`

The type name describing `$.payload`. Normally borrowed from [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/Grammar/Value.md).

Defaults to *"any"*.

METHODS
=======

### `node-name()`

Returns node class `shortname`.

COERCIONS
=========

The role supports specialized coercion from [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/Grammar/Value.md):

    my Config::BINDish::AST::Container $c = Config::BINDish::AST::Value($grammar-value);

In this case new container's payload and type name are set from corresponding attributes of [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/Grammar/Value.md) instance. The `payload` is obtained using the `coerced` method of [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/Grammar/Value.md).

For any other kind of value it is stored in the `$.payload` attribute. And the type name is set to lowercased name of the value's class. The only exception is any of `Stringy`-consuming class for which the type name is set to *"sq-string"*.

### `multi ACCEPTS(Config::BINDish::AST::Container:D $val)`

Matches `$val.payload` against our `$.payload`

### `multi ACCEPTS(Any:D $val)`

Matches `$val` against our `$.payload`.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

