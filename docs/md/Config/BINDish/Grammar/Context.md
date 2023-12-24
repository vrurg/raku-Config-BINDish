# NAME

`Config::BINDish::Grammar::Context` - parsing context representation

# DESCRIPTION

Instance of this class represents information about the current parsing context.

# ATTRIBUTES

### [`Str:D`](https://docs.raku.org/type/Str) `$.type`

The type of the current context. The core grammar knows about *block* and `option` contexts. But an extension can define its own type.

### `$.id`

ID of the current context statement, if it has one.

### [`Config::BINDish::Grammar::Value`](Value.md) `$.keyword`

Keyword used to create context. For example, for a block context created with

``` 
foo { }
```

this attribute will be set to a `Value` where `payload` attribute is a [`Match`](https://docs.raku.org/type/Match) against *foo* part of the block.

### [`Config::BINDish::Grammar::Value`](Value.md) `$.name`

Name of the current context. Currently can only be set for named block contexts.

### `Config::BINDish::Grammar::Context` `$.parent`

Parent context. Undefined for `.TOP`.

### [`Config::BINDish::Grammar::StatementProps`](StatementProps.md) `$.props`

Properties of the context statement if it is pre-declared.

### `$.relations`

A hash of keywords of pre-declared statements which are valid in the current block context. See `prop-relations` attribute of [`Config::BINDish::Grammar`](../Grammar.md).

# METHODS

### `cur-block-ctx(--> Config::BINDish::Grammar::Context)`

Returns self if current context is a block; or the innermost enclosing block context.

### `is-TOP()`

Returns *True* if current block context belongs to `.TOP`.

### `description()`

Returns a string, in a human-readable form, describing the current context.

### `ACCEPTS(StatementProps:D $props)`

Returns *True* if a pre-declared statement can be used in the enclosing block context.

# SEE ALSO

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::Grammar`](../Grammar.md), [`Config::BINDish::Grammar::BlockProps`](BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](OptionProps.md)

# AUTHOR

Vadim Belman <vrurg@cpan.org>
