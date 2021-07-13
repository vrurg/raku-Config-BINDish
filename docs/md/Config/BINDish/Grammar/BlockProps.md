NAME
====

`Config::BINDish::Grammar::BlockProps` - block statement properties

DESCRIPTION
===========

Does [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish/Grammar/ContainerProps.md), [`Config::BINDish::Grammar::DeclarationProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish/Grammar/DeclarationProps.md).

ATTRIBUTES
==========

### [`Bool`](https://docs.raku.org/type/Bool) `$.named`

If *True* then block must have a name.

### [`Bool`](https://docs.raku.org/type/Bool) `$.classified`

If *True* then block must have a class. Only makes sense when `$.named` is *True*.

### [`Bool`](https://docs.raku.org/type/Bool) `$.value-only`

If *True* then block can only contain values. For example:

    acl "local-net" allowed {
        192.168.42.0/24; 192.168.13.0/24;
        default-gw 192.168.1.1; # Context error, option cannot be used here
    }

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish/Grammar.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.4/docs/md/Config/BINDish/Grammar/OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

