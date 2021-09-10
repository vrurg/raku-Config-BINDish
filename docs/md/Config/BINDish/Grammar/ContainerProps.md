ROLE
====

`Config::BINDish::Grammar::ContainerProps` - common properties of container statements

DESCRIPTION
===========

Does [`Config::BINDish::Grammar::TypeStringify`](TypeStringify.md).

A container statement is the one which can contain a value. The only two pre-declarable kind of statements currently supported: options and blocks – are both containers.

ATTRIBUTES
==========

### `List(Str)` `$.value-sym`

List of sym names of `value` token, allowed for this kind of container. For example, if we want an option `foo` to only accept numeric values then this list must contain `int`, `num`, and `rat`. In this case the grammar will only attempt to match option value using tokens `value:sym<int>`, `value:sym<num>`, and `value:sym<rat>`, respectively.

### Mu `$.type`

Must be a type object, which is the type this container is constrained to. Can be a [`Junction`](https://docs.raku.org/type/Junction) in which case the type of possible container value is matched against the junction. For example: `Num | Rat` would restrict the container to only [`Num`](https://docs.raku.org/type/Num) or [`Rat`](https://docs.raku.org/type/Rat) values.

### `$.type-name`

Contains allowed type name for this container. For example, to restrict a container to keywords only `$.type` must be set to [`Str`](https://docs.raku.org/type/Str), and type name set to *"keyword"*.

METHODS
=======

### `ACCEPTS(`[`Config::BINDish::Grammar::Value:D`](Value.md)`$val)`

Returns *True* if `$val` matches this container constraints on data type and type name.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::Grammar`](../Grammar.md), [`Config::BINDish::Grammar::BlockProps`](BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

