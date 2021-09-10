NAME
====



[`Config::BINDish`](docs/md/Config/BINDish.md) - parse BIND9/named kind of config files

SYNOPSIS
========



    my $cfg = Config::BINDish.new;
    $cfg.read: string => q:to/CFG/;
        server "s1" {
            name "my.server";
            paths {
                base /opt/myapp;
                pool "files" static {
                    ./pub/img;
                    "static/img";
                    "docs";
                };
                pool "files" dynamic {
                    "users/reports";
                    "system/reports"
                }
            }
        }
        CFG
    say $cfg.top.get( :server("s1") => :paths => :pool("images") => 'root' ); # ./pub/img

DISCLAIMER
==========



This module is very much experimental in the sense of the API it provides. The grammar is expected to be more stable, yet no warranties can be given at the moment.

Also, all the documentation here is created in write-only mode. No proof-reading has been done so far. All kinds and levels of ugliness and errors are anticipated! My apologies for the situation, hope to get some spare hours to fix it some day in the future.

PREFACE
=======



Introduction
------------

The purpose of this module is to parse [BIND 9-like](https://bind9.readthedocs.io/en/latest/configuration.html) configuration files. Why *BINDish* then? Because the *"-like"* suffix above is the key. Theoretically, `Config::BINDish` is capable of parsing the native `named` configuration files; practically, it lacks support of few syntax constructs like barewords as references to named configuration blocks.

Aside of that, it can parse configuration using relaxed syntax where the terminating semi-colon is optional. Look at the [SYNOPSIS](#SYNOPSIS) again; from the perspective of `named` the example is invalid from the syntax point of view.

So, from this moment on I will refer to the format as to *BINDish config* format. Or just *BINDish* sometimes.

Why BINDish?
------------

Because among the well-known configuration formats this one is one of the most powerful and flexible. Here is my point:

  * XML? Thank you, but - **no!** Any questions, anyone?

  * JSON is ok, but rather limited in capabilities. The lack of comments is especially frustrating

  * YAML is the power which comes with mandatory indentation and sometimes confusing rules

  * Win-style INI, TOML are a great compromise and I was often finding myself using one or another variant of these. Yet, sometimes I'd love to have nested sections, but they don't fit well into these

That's about it. What makes BINDish different are:

  * Sectioning with help of configuration blocks. Event the ability to give them names and classfy same-named blocks is already powerful enough to break your config into nicely grouped options. Yet, with naturally looking and unlimited nesting of blocks it becomes easier task.

  * Optional naming and classifying of blocks doesn't constrain ones freedom in defining the best configuration content.

  * One doesn't have to count spaces in mind. There is no risk of an overly *smart* editor would accidentally re-indent the config in a way it would get totally different meaning.

  * Easy to read. Really, really easy to get into the content of a config from the first glance. Just by looking at the [SYNOPSIS](#SYNOPSIS) example you can easily guess what's going on and what to expect from the software using this file!

  * Easy to extend. Not in the original BIND 9 implementation, of course. But for a third-party parser, like this one, it shouldn't be a big problem to allow `path /to/my/dir;` instead of `path "/to/my/dir";`. This module goes even further down the road; but I'll get back to this a bit later.

SYNTAX
======



Very roughly, the configuration format supported by the module can be described as:

    <config> ::= <statements>
    <statements> ::= <empty> | <statement> | <statement> <statements>
    <statement> ::= <block> | <option> | <comment>
    <block> ::= <block-type> [<block-name> [<block-class>]] '{' <statements> '}' [';']
    <option> ::= <keyword> [<value>] [';']
    <block-type> ::= <keyword>
    <block-name> ::= <value>
    <block-class> ::= <keyword>
    <keyword> ::= <alpha> [ <alphanumeric> | '-' ]*
    <value> ::= <bool> | <string> | <int> | <num> | <rat> | <file-path> | <keyword>

Here is a sample config:

    top-level-option "global value";
    pi 3.1415926;
    category "1" {
        description "something meaningful";
        public; // Option is set to True value
        products {
            "item 1"; "item 2"; "item 3";
        };
    }

A config can be parse in either strict or relaxed mode. Depending on chosen mode, the terminating semi-colon can be either optional or mandatory. For the above sample in strict mode the `category` block declaration would be an error because its closing `}` is not followed with `;`. Contrary, in relaxed mode one can safely remove the ending semi-colon after `products` as as well as after `"item3"` too.

More information about strictness modes can be found in [`Config::BINDish::Grammar::Strictness`](docs/md/Config/BINDish/Grammar/Strictness.md)

Note how term `block-name` in the grammar is declared as a `value`. It means that any valid option value can serve as the block name. For example:

    block 3.14 { }

Or, with [`Config::BINDish::INET`](docs/md/Config/BINDish/INET.md) loaded it could even be:

    network 192.168.1.0/24 {
    }

Comments
--------

Similarly to the original BIND 9 format, `Config::BINDish` supports C, C++, and Unix-style comments:

    // C++
    /*
     * C
     */
    # Unix

Comments are considered statements on their own. This limits where a comment can be placed. For example, it's not possible to have a comment inside an option or a block declaration:

    pi /* not ok between option keyword and value! */ 3.1415926; # but it's ok post-option
    server /* not allowed here! */ 1 { // But here
        /*
         * or here
         * where we can make it a comprehensive description
         */
    }

Options
-------

An option is declared with a keyword and an optional value. If the value is omitted then option is considered to have a *true* boolean value:

    option; # True
    option on; # Same as above
    foo yes; # Also true
    bar off; # False
    min-size 1024; # or 1K
    max-size 1.5M;
    description "bla-bla-bla";
    refers_to a-block; # same as using "a-block" but can serve as a hint of special case

Options are characterized by three properties inherited from their values: the payload which is the value itself; Raku value type; and a type name providing more information about the purpose of the value. For example, the option `description` from the above example is a [`Str`](https://docs.raku.org/type/Str) with type name *dq-string* which is a shorthand for "double-quoted string". A string can also be single-quoted, or *sq-string*. Now, when we need this, we can decide how to handle a string value based on its type name. Traditionally one could expect a double-quoted string to be expanded if it contains references to other options.

Options can be pre-declared. It means that for some options the parser may impose certain restrictions. One of the most typical constraints would be option's type. Say, `max-size` can be set to only be OK if its value is an integer. Then whenever parser finds something like

    max-size "1024";

It will throw an error.

An option can also be limited as to where it can appear. For example, if a `resolver` option is set to be allowed only inside a `network` block then:

    network "office" {
        resolver "default"; # OK
    }
    resolver "default"; # Error: option cannot be used here

Moreover, if strict mode is set for options the parser will only allow pre-declared ones.

Including Configs
-----------------

With `include <source>` statement a configuration from `<source>` is injected into the location where the `include` is used. For example, we have a file *common.inc*:

    foo 42;
    bar {
        message "thanks for the fish!";
    }

And a config akin to the followin one:

    include ./common.inc;
    baz {
        include ./common.inc;
    }

Now option `foo` is available both at the top and block `baz` contexts, as well as block `bar`.

Blocks
------

Blocks purpose is to logically group a set of options or other blocks.

Block is declared with a type, a name, and a class. The only mandatory element of block declaration is the type:

    foo { }             # Minimal declaration
    foo "bar" { }       # A named block
    foo "bar" class { } # A named and classified block

The concept of classifying was taken from BIND 9 configuration format. But it can be proved to be useful in complex setups. Consider for example:

    rack "A001.2" servers { ... };
    rack "A001.2" patch-panels { ... };
    rack "A001.2" switches { ... };

Apparently, classes could be incorporated into the name part of a block declaration, or be a part of block type (so, we get `rack-switches`), but the above example most certainly looks way better than the alternatives.

There is no limit on nesting blocks:

    rack "A001.2" servers {
        server "nas-1" {
            interface 1 {
                network "office";
            }
            interface 2 {
                network "warehouse";
            }
        }
    }
    network "office" {
        cidr "172.1.2.0/24";
        gw "172.1.2.1";
        nameservers {
            "172.1.2.5";
            "172.1.5.5";
        }
    }

*NB* We use strings for IP addresses. But with bundled [`Config::BINDish::INET`](docs/md/Config/BINDish/INET.md) extension one can have it like `gw 172.1.2.1;`. But this paper tries to stick to the barebones module as much as possible.

So far the examples written as if the parser works in relaxed mode. In strict mode the rule of *mandatory semi-colon* applies and a block must always be terminated with `;`:

    network { ... };

An option can also omit the semi-colon if it is followed by a closing curly in non-strict mode:

    interface 1 { network "office" }

One could have already noticed `nameservers` block in the above extensive example. This is a kind of thing often to be met in BIND 9 configuration. For example, this is how ACLs are declared:

    acl our-nets { x.x.x.x/24; x.x.x.x/21; };

Apparently, `Config::BINDish` also supports this kind of syntax and call it "value blocks". But a value block is not by default limited to values only and can also contain options or subblocks:

    nameservers {
        "172.1.2.5";
        "172.1.5.5";
        foreign "google" {
            "8.8.8.8";
            priority -100;
        }
        foreign "provider" {
            "A.B.C.D";
            priority -1;
        }
    }

Here we have two additional value subblocks defining fallback nameservers for cases when our own ones are down. Oops, but we all know – s... things happen!

Yet, a block could be limited to be a value-only one. In this case the above example will become an error. Aside of this and similarly to options, blocks can also be restricted as to:

- where they can appear - whether they require a name or/and a class - what value type(s) can be used within the block

Directives
----------

`Config::BINDish` supports special directives similar to what C is using. Currently the only implemented directive is `#line`:

    #line 13 "mock-file.conf" Here go a comment

The meaning of the directive is the same as in C: it makes the grammar to pretend that lines below the directive are located in file *mock-file.conf* starting with its line 13. If the directive is followed by something like this:

    #
    opt 1 2 3;

then when a error is reported it will point at line 14 in *mock-file.conf*.

Note that the file name part of `#line` can either be omitted or use any valid option value. For example, with [`Config::BINDish::INET`](docs/md/Config/BINDish/INET.md) one can do something like:

    #line 1 https://configs.local/common/std.inc

It would then be only a matter of overriding [`Config::BINDish::Grammar`](docs/md/Config/BINDish/Grammar.md) `include-source` method to provide support for URLs.

Hybrid mode
-----------

It is possible for a grammar to run in relaxed mode but still have some options and/or blocks pre-declared. These pre-declarations are always respected by the parser. This mode of operation when some options/blocks are constrained while others are ok to be free-form is called *hybrid mode*.

Module Extensibility
--------------------

One of the key ideas behind this module is the ability to extend its parsing capabilities by 3rd-party modules or user code. Normally this could be done by creating roles with `BINDish-grammar` or `BINDish-actions` traits applied. ([`Grammar`](https://docs.raku.org/type/Grammar)). Most of the time the purpose of such extensions would be to provide new value types. But they could as well add new syntax constructs, or change behavior of the existing ones, or something I currently can't forecast. When one starts with

    role MyExt::Grammar is BINDish-grammar {
    }
    role MyExt::Actions is BINDish-actions {
    }

where they end is totally up to them!

SEE ALSO
========

[`Config::BINDish`](docs/md/Config/BINDish.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

