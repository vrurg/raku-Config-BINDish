CLASS
=====

`Config::BINDish::Actions` - default actions for [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md)

DESCRIPTION
===========

This class is the default to be used for parsing configs. It builds [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST.md) tree representation of a config data which is then provided to application code via [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md) attribute `$.top`. The tree can be used to fetch required configuration data, see [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST.md).

METHODS
=======

Most of the methods correspond to named rules in [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md). In this section only utility methods are documented.

### `make-container(Config::BINDish::Grammar::Value:D $val)`

Method creates a new instance of [`Config::BINDish::AST::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Value.md) from its grammar counterpart.

### `enter-parent(Config::BINDish::AST::Node:D $inner --` Config::BINDish::AST::Node:D)>

### `enter-parent(Config::BINDish::AST::Node:U $inner, |profile --` Config::BINDish::AST::Node:D)>

Method is invoked when a new [`Config::BINDish::AST::Node`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Node.md) is to be created. For example, this class uses it when creates the `TOP` node and each time a new block node is created. [`Config::BINDish::Extendabale`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Extendabale.md) also uses this method for another kinds of nodes.

If `$inner` is an undefined typeobject then the method first creates an instance of it using method `new` and using `profile` as its arguments:

    $inner.new(|profile)

Method sets `$*CFG-INNER-PARENT`.

### `inner-parent()`

Returns the innermost parent node.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

