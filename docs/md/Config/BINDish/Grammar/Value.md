# CLASS

`Config::BINDish::Grammar::Value` - grammar representation of a value

# ATTRIBUTES

### [`Match:D`](https://docs.raku.org/type/Match)`| `[`Str:D`](https://docs.raku.org/type/Str)`$.payload`

The actual value representation. Most of the time it would be a [`Match`](https://docs.raku.org/type/Match) obtained from parsed down source. But some values might be represented by strings if they're some kind of defaults.

### [`Str:D`](https://docs.raku.org/type/Str) `$.type-name`

Value type name.

### [`Mu`](https://docs.raku.org/type/Mu) `$.type`

Value type object.

# SEE ALSO

  - [`Config::BINDish`](../../BINDish.md)

  - [`Config::BINDish::Grammar`](../Grammar.md)

  - [`Config::BINDish::Grammar::TypeStringify`](TypeStringify.md)

  - [`Config::BINDish::Grammar::ContainerProps`](ContainerProps.md)

  - [`README`](../../../../../README.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
