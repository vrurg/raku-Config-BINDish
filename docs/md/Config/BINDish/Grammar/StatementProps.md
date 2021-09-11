ROLE
====

`Config::BINDish::Grammar::StatementProps` - standard statement properties

DESCRIPTION
===========

This role defines properties common to all pre-declarable statements.

ATTRIBUTES
==========

### [`SetHash:D()`](https://docs.raku.org/type/SetHash) `$.in`

Set of block IDs in which a statement can be used.

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.autovivified`

When *True* this statement declaration was autovivified by the parser. This can happen, for example, when an option has a block referenced in its `$.in` and the block is not explicitly declared.

METHODS
=======

### `ACCEPTS(Config::BINDish::Grammar::Context:D $ctx)`

Checks if this statement can be used in context `$ctx` by locating the nearest enclosing block context and verifying if the block is mentioned in statement's `$.in` set. Always matches if `$.in` is empty.

### `Bool()`

Coerces a property object into *False*. See method `get` in [`Config::BINDish::AST::Blockish`](../AST/Blockish.md) for details about default values.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::Grammar`](../Grammar.md), [`Config::BINDish::Grammar::BlockProps`](BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

