NAME
====

`Config::BINDish::Grammar::BlockProps` - block statement properties

DESCRIPTION
===========

Does [`Config::BINDish::Grammar::StatementProps`](StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](ContainerProps.md), [`Config::BINDish::Grammar::DeclarationProps`](DeclarationProps.md).

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

METHODS
=======

### `values()`

Coerces `$.default` attribute to [`List`](https://docs.raku.org/type/List) and returns it. If the attribute is not set then returns an empty list.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::Grammar`](../Grammar.md), [`Config::BINDish::Grammar::OptionProps`](OptionProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

