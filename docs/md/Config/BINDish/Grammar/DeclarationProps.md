# NAME

`Config::BINDish::Grammar::DeclarationProps` - common properties of declarable statements

# DESCRIPTION

This role must be consumed by statements are identified by a keyword and have a unique ID. This requirement applies to both options and blocks.

# ATTRIBUTES

### [`Any:D`](https://docs.raku.org/type/Any) `$.id`

A unique identifier.

### [`Any:D`](https://docs.raku.org/type/Any) `$.keyword`

A keyword associated with statement. Not necessarily unique as same keyword may be used in different block contexts and be mapped to different IDs. See [`Config::BINDish::Grammar::StatementProps`](StatementProps.md), `$.in` attribute.

# SEE ALSO

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::Grammar`](../Grammar.md), [`Config::BINDish::Grammar::BlockProps`](BlockProps.md), [`Config::BINDish::Grammar::OptionProps`](OptionProps.md)

# AUTHOR

Vadim Belman <vrurg@cpan.org>
