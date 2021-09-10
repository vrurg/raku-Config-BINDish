CLASS
=====



`Config::BINDish::Grammar::Value` - grammar representation of a value

ATTRIBUTES
==========



### [`Match:D`](https://docs.raku.org/type/Match)`| `[`Str:D`](https://docs.raku.org/type/Str)`$.payload`

The actual value representation. Most of the time it would be a [`Match`](https://docs.raku.org/type/Match) obtained from parsed down source. But some values might be represented by strings if they're some kind of defaults.

### [`Str:D`](https://docs.raku.org/type/Str) `$.type-name`

Value type name.

### [`Mu`](https://docs.raku.org/type/Mu) `$.type`

Value type object.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md), [`Config::BINDish::Grammar::TypeStringify`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/TypeStringify.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/ContainerProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

