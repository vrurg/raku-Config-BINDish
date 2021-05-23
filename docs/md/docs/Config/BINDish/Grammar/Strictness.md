CLASS
=====



`Config::BINDish::Grammar::Strictness` - strict mode options

DESCRIPTION
===========



This class defines what parts of the parser should operate in strict mode. See [ATTRIBUTES](#ATTRIBUTES).

The most simple way to initialize an instance of this class is to coerce it from a [`Bool`](https://docs.raku.org/type/Bool) value:

    Config::BINDish::Grammar::Strictness(True); # All strict

From the perspective of creating a new grammar it would be done as:

    Config::BINDish::Grammar.parse(..., :strict);   # All strict
    Config::BINDish::Grammar.parse(..., :!strict);  # All non-strict

ATTRIBUTES
==========



### [`Bool:D`](https://docs.raku.org/type/Bool) `$.syntax = False`

When set the parser will require a semi-colon (`;`) after all statements. Otherwise semi-colon is optional after block's closing curly brace, and after an option if it is followed by a closing brace. The following example is ok when syntax is non-strict:

    block {
        option "foo"
    }

Otherwise it has to be like this:

    block {
        option "foo";
    };

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.options = False`

This attribute determines if all options have to be explicitly pre-declared.

See method `declare-options` in [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar.md).

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.blocks = False`

This attribute determines if all block types have to be explicitly pre-declared.

See method `declare-blocks` in [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar.md).

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

