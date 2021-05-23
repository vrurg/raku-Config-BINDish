NAME
====

`Config::BINDish::Expandable` - `Config::BINDish` extension implmeneting expandable strings

DESCRIPTION
===========

This module extends [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish.md) with strings which can include other option values. Only double-quoted string (i.e. those for which [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/Grammar/Value.md) and [`Config::BINDish::AST::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/AST/Value.md) have type name set to *dq-string*) are expandable.

To incorporate a value into a string the following macro format is used:

    '{' <option> | <option-path> '}'

*option* is a plain string naming an option from the current block:

    server "S1" {
        name "server.local";
        description "{name} is a mock server"; # becomes "server.local is a mock server"
    }

*option-path* defines a path to the option if it is located in another block. The path can be relative or absolute.

The absolute path is started with a slash:

    base-url "https://localhost"
    resource "Test" {
        url "{/base-url}/test";
    }

To define a block where the option is to be located the following syntax is used:

    block-type[([name [, class]])]

For example:

    resource "default" {
        url "https://localhost";
    }
    resource "test1" addr {
        component "foo"
    }
    client-data {
        url "{/resource(default).url}/{/resource("test1", addr).component}"; # https://localhost/foo
    }

Nested blocks are joined with a dot:

    resource "default" {
        urls {
            base "https://localhost";
        }
    }
    client-data {
        user-profile "{/resource(default).urls.base}/user"; # https://localhost/user
    }

Symbol escaping is traditionally done with a backslash:

    client-data {
        description "Some basic info \{?} \\";
    }

This Is A Value!
----------------

Because expandable strings are normal values they can be used anywhere, where a value is accepted we can do things like expanding a string within a macro:

    default-server "A1";
    server "A1" {
        url "https://a1.local";
    }
    server "A2" {
        url "https://a2.local";
    }
    network "Office" {
        api-url "{/server("{/default-server}")}/api"; # https://a1.local/api
    }

This works because when a macro is expanded server name and class can be specified using string values.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.1/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>
