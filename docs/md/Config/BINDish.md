NAME
====

`Config::BINDish` - parse BIND9/named kind of config files

SYNOPSIS
========



    my $cfg = Config::BINDish.new;
    $cfg.read: string => q:to/CFG/;
    server "s1" {
        name "my.server";
        paths {
            base "/opt/myapp";
            pool "files" static {
                "pub/img";
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

    $cfg.read: file => $my-config-filename;

DISCLAIMER
==========

This module is very much experimental in the sense of the API methods it provides. The grammar is expected to be more stable, yet no warranties can be given at the moment.

DESCRIPTION
===========

In this documentation I'll be referring to the configuration format implemented by the module as *BINDish config* or simply *BINDish*.

EXTENSIONS
==========

BINDish configuration parser can be augmented with 3rd-party extensions. Every extension is implemented as a role which will be used to build the final grammar or actions classes (see [`Grammar`](https://docs.raku.org/type/Grammar)). The classes are based upon [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar.md) and [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md) respectively. Here is the steps `Config::BINDish` does to build them:

  * An empty class is created which will serve as the final version

  * Extension roles are punned and added as parents to the class

  * Then the base class is added as the last parent

The order in which the extensions are added is defined by the order and the way they're registered. The later added ones serve as the earlier parents meaning that Raku's method call dispatching will have their methods invoked first.

There are two and a half ways to extend the parser. First is to use `is BINDish-grammar` or `is BINDish-actions` trait:

    unit module Config::BINDish::Ext1;
    role Grammar is BINDish-grammar {
        token value:sym<mine> {
            ...
        }
    }
    role Actions is BINDish-actions {
        method value:sym<mine>($/) {
            ...
        }
    }

In this case the role they're applied to will be auto-registered with `Config::BINDish`. When such extension is contained by a module then it would be added when the module is `use`d:

    use Config::BINDish::Ext1;
    use Config::BINDish::Ext2;

*Note* that considering the order of `use` statements, `Ext2` will be able to override methods of `Ext1`.

The specificifty of using the traits is that extensions declared this way will become application-wide available. So, even if the extension module is used by a module used by the main code, the extension will be available to any instance of `Config::BINDish`.

**Note:** We say that extensions registered with the traits are registered *statically*.

The other 1.5 ways of adding the extensions are to use `extend-grammar` and `extend-actions` constructor arguments or methods with the same names:

    my $cfg = Config::BINDish.new: :extend-grammar(ExtG1, ExtG2), :extend-actions(ExtA1, ExtA2);
    $cfg.extend-grammar(ExtG3)
        .extend-actions(ExtA3);

In this case extension roles don't need the traits applied. This way we call *dynamic* registration.

The other specific of dynamic extensions is that they will go after the static ones. I.e. in the above examples `ExtG*` and `ExtA*` will be positioned before `Ext1` and `Ext2` in the MRO order, prioritizing the former over the latter ones.

Why is the above called *1.5 ways*? Because the constructor eventually uses the `extend-*` methods with corresponding `:extend-*` named attributes.

See also [`Config::BINDish::Grammar`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar.md) and [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md).

ATTRIBUTES
==========

[`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Strictness.md) `$.strict`
----------------------------------------------------------------------------------------------------------------------------------------------------------

The default grammar strictness mode. See [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Strictness.md) documentation for details.

`%.blocks`, `%.options`
-----------------------

These two attributes contain user-defined structure of the config file. More information about them can be found in [Config::BINDish::Grammar](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar.md) documentation, methods `declare-blocks` and `declare-options`.

`$.grammar`, `$.actions`
------------------------

The final grammar and actions class versions with all registered extensions applied. Both attributes are *lazy* and `clearable` in terms of [`AttrX::Mooish`](https://modules.raku.org/dist/AttrX::Mooish:cpan:VRURG). It means that the following is possible:

    say $cfg.grammar.^name; # Config::BINDish::Grammar...
    $cfg.extend-grammar(MyApp::GrammarMod);
    $cfg.clear-grammar;     # Actually, extend-grammar already does this. This line is here to demo the concept only.
    say $cfg.grammar.^name; # Config::BINDish::Grammar+{MyApp::GrammarMod}...

[`IO::Path`](https://docs.raku.org/type/IO::Path) `$.file`
----------------------------------------------------------

If `read` method was called with `:file<...>` argument then this attribute will hold corresponding `IO::Path` object for the file name.

[`Bool`](https://docs.raku.org/type/Bool) `$.flat = False`
----------------------------------------------------------

If set to `True` then [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md) will act in flattening mode.

`$.top`
-------

The top node produced by the grammar actions. I.e. it is the result of `$<TOP>.ast` of the [`Match`](https://docs.raku.org/type/Match) object produced by grammar's `parse` method. For [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md) it would be an instance of [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST.md). But an extension can produce something to its taste which wouldn't be an AST whatsoever. The only requirement imposed on the object stored by the attribute is to provide `get` method.

This attribute `handles` method `get`.

`$.match`
---------

This attribute stores the [`Match`](https://docs.raku.org/type/Match) object produced by grammar's `parse` method.

METHODS
=======

`extend-grammar( +@ext )`, `extend-actions( +@ext )`
----------------------------------------------------

Interface to dynamically register extensions. Take a list of roles and records them as extensions. Then it clears `$.grammar` or `$.actions` attributes, respectively. Both return `self` to allow method call chaining.

`build-grammar()`, `build-actions()`
------------------------------------

Methods used by [`AttrX::Mooish`](https://modules.raku.org/dist/AttrX::Mooish:cpan:VRURG) to lazily initialize `$.grammar` and `$.actions` attributes respectively.

`multi method read(Config::BINDish:U: |args)`

Instantiates `Config::BINDish` class and re-invokes `read` method on the instance with `args` capture.

`multi method read(IO:D(Str:D) :$file, |args)`, `multi method read(Str:D :$string, |args)`
------------------------------------------------------------------------------------------

Parses a configuration stored either in a `$string` or in a `$file` and returns the resulting [`Match`](https://docs.raku.org/type/Match) object. The capture `args` is passed over to the `parse` method of `$.grammar` alongside with `$.actions`, `$.strict`, `$.flat`, `%.blocks`, and `%.options` attributes.

The method returns what is returned by grammar's `parse` method. The same value is then stored in `$.match` attribute.

### `multi get(...)`

Method is handled by `$.top` attribute. See [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Parent.md) for detailed method description.

SEE ALSO
========

[README.md](README.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

