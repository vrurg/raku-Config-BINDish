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

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md), [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

