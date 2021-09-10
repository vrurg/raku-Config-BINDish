NAME
====

`Config::BINDish::Grammar::DeclarationProps` - common properties of declarable statements

DESCRIPTION
===========

This role must be consumed by statements are identified by a keyword and have a unique ID. This requirement applies to both options and blocks.

ATTRIBUTES
==========

### [`Any:D`](https://docs.raku.org/type/Any) `$.id`

A unique identifier.

### [`Any:D`](https://docs.raku.org/type/Any) `$.keyword`

A keyword associated with statement. Not necessarily unique as same keyword may be used in different block contexts and be mapped to different IDs. See [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/StatementProps.md), `$.in` attribute.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md), [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

