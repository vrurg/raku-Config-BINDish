NAME
====

`role Config::BINDish::AST::Decl` - a declarable entity

DESCRIPTION
===========

This role must be consumed by any node which can be declared with a keyword

ATTRIBUTES
==========

### [`Config::BINDish::AST::Container:D`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Container.md) `$.keyword`

The keyword used to declare AST node. There is no limitation as to container's type. In other words, a node can be declared using a rational number; or a specialized kind of value provided by an extension. Say, for a network configuarion we can have something like:

    192.168.1.0/24 {
        ns1 192.168.1.5;
    }

and it's gonna be a valid declaration as soon as [`Config::BINDish::INET`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/INET.md) is loaded.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

