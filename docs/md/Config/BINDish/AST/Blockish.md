ROLE
====

`role Config::BINDish::AST::Blockish` - interface of a generic block class

DESCRIPTION
===========

This role mostly implements basic block search capabilities provding interface for locating and pulling out various kinds of children objects.

ATTRIBUTES
==========

### `$.id`

Unique ID of a blockish object. See [`Config::BINDish::Grammar Pre-declaration`](../Grammar.md#Pre-declaration) section.

METHODS
=======

### `multi find(:$block!, :$name, :$class, Bool :$local --> Config::BINDish::AST::Block)`

Similar to `find-all(:$block!, ...)` candidate but makes makes sure that only one block entry is found. It either returns the block instance found, or [`Nil`](https://docs.raku.org/type/Nil), or throws with [`Config::BINDish::X::Block::Ambiguous`](../X/Block/Ambiguous.md) if more than one candidate found.

### `multi find(:$option!, Bool :$local --> Config::BINDish::AST::Option)`

Similar to the candidate for `:$block!`, but for options. Returns [`Config::BINDish::AST::Option`](Option.md). Throws with [`Config::BINDish::X::Option::Ambiguous`](../X/Option/Ambiguous.md).

### `block($block, Bool :$local, *%p)`

A shortcut for `$node.find(:$block, :$local, |%p)`.

### `blocks($block, *%p)`

A shortcut for $<$node.find-all(:$block, |%p)>.

### `option($option, Bool :$local = True, *%p)`

A shortcut for `$node.find(:$option, :$local, |%p)`. Note that `$local` is *True* by default as this is the most anticipated mode of operation. With `:!local` it's still possible to do a recursive search for a unique option instance.

### `options($option, Bool :$local = True, *%p)`

A shortcut to `$node.find-all(:$option, :$local, |%p)`. Note that `$local` is also set to *True* by default, as for `option` method above. This is still meaningful because a block may contain multiple options of the same name.

### `value($option, Bool :$local = True, *%p)`

This method is similar to the `option` method above except that `value` returns not option but payload of the option's value.

### `values(Bool :$raw)`

Returns block's standalone values. For example, for the following example it will return `1, 2, 3`:

    block "foo" {
        1; 2; 3;
    }

If `$raw` named argument is used then instead of payloads the method will return instances of [`Config::BINDish::AST::Value`](Value.md).

Method `get`
------------

This is an umbrella method which provides a few ways of accessing configuration data. It is also considered the primary means of accessing configuration data stored on an AST.

### Default Values

One of the key features of `get` which sets it apart of methods `value`, `option`, `block`, etc., is its ability to return some kind of default for a requested configuration element which is actually missing from the config file. For example, if we have a [`pre-declaration`](../Grammar.md#Pre-declaration) like this:

    blocks => (
        :host => %( :named ),
    ),
    options => (
        :host-iface<interface> => %( :in<host>, :default<*> ),
    )

And then request the value of `interface` option from a config file like:

    host "srv1.local" {
        ip 192.168.1.42;
    }

Then the method will supply us with string *"*"* which it would find in corresponding [`Config::BINDish::Grammar::OptionProps`](../Grammar/OptionProps.md), created from the above pre-declaration structure.

For a missing option with no default value (or no pre-declaration whatsoever) `Nil` will be returned.

Whenever we expect an option or a block object to be returned (see `:raw` parameter in the followin sub-sections) instead of [`Config::BINDish::AST::Option`](Option.md) or [`Config::BINDish::AST::Block`](Block.md) instance the method would return [`Config::BINDish::Grammar::OptionProps`](../Grammar/OptionProps.md) or [`Config::BINDish::Grammar::BlockProps`](../Grammar/BlockProps.md), respectively, if the requested elements do have corresponding pre-declarations. For example, for the above config snippet:

    $cfg.get( :host<srv1.local> => "interface", :raw )

an instance of `OptionProps` will be returned. If one misspells the option name like, say, *"intrface"* then the method will return `Nil`, same as for when a value is requested. Yet, in either case one can test against the return value to know if the option exists in the config file:

    ? $cfg.get( :host<srv1.local> => "interface", :raw ); # False
    ? $cfg.get( :host<srv1.local> => "intrface", :raw );  # False
    ? $cfg.get( :host<srv1.local> => "ip", :raw );        # True

This is because all `OptionProps` and `BlockProps` objects are *falsy* in a boolean context. This way one can check it out if an option or a block is actually present in the config. To find out if the requested option or block is not in the config and neither has a pre-declaration one can use `.defined` on the return value or test it against `Nil`.

### `multi get(Str:D $option, Bool :$raw, Bool :$local = True)`

By default returns `$option` value. With `:raw` argument will return corresponding [`Config::BINDish::AST::Option`](Option.md) or [`Config::BINDish::Grammar::OptionProps`](../Grammar/OptionProps.md) object.

With `:!local` will search for the option recursively.

    $block.get("foo");         # Option "foo" value
    $block.get("foo", !local); # Option "foo" value in this or any nested block

### `multi get(Str:D :$option, Bool :$local = True)`

Returns an option object. A shortcut for `$block.get($option, :$local, :raw)`.

### `multi get(Str:D :$value, Bool :$local = True)`

Returns an option value. Note that `$value` must contain option keyword:

    $block.get: :value<foo>; # Option "foo" value

A shortcut for `$block.get($value, :$local, :!raw)`.

### `multi get(Str:D $keyword, :block)`

Returns a nameless block located by `$keyword` locally on the invocator.

### `multi get(Str:D :$block, *%c)`

Finds and returns a block object by its keyword. A shortcut for `$block.get($block, :block)`.

### `multi get(Pair:D $path, Bool :$block, Bool :$raw, Bool :$local)`

This is the most advanced form of `get` method. It allows to find an option or block by its path. The path is defined as a nested structure of [`Pair`](https://docs.raku.org/type/Pair)s. For each `Pair` its key specifies a subblock within its parent block; its value specifies an object within the subblock:

    # Get option "fubar" from a top block "foo"
    $cfg.top.get(:foo<fubar>);
    # Get "fubar" from block "baz" inside block "bar", inside block "foo"
    $cfg.top.get(foo => bar => baz => "fubar");
    $cfg.get(:foo(:bar(:baz<fubar>))); # Same as above

Both key and value can be [`Pair`](https://docs.raku.org/type/Pair) on their own. When key is a [`Pair`](https://docs.raku.org/type/Pair) then it is considered a block reference. Its key defines block type, its value defines block name and, possibly, class:

    # find in `foo "bar" { ... }`
    :foo<bar> => ...;

    # find in `foo "bar" baz { ... }`
    :foo("bar", "baz") => ...;

When pair's value is a [`Pair`](https://docs.raku.org/type/Pair) on it's own it is considered to be a subpath, to be handled recursively. I.e., in the above example of `foo => bar => baz => "fubar"` the value `bar => ...` is a path, then `baz => "fubar"` is too. But then when we reach *"fubar"* it is considered to be the object the method is requested for.

Let's use an example from tests:

    multi "1" {
        opt 42;
        subblk "level 1.a" {
            opt 1.3;
            subsubblk "level 2" nesting {
                opt2 "π";
            }
        }
        subblk "level 1.a" special {
            opt -1.3;
        }
        subblk "level 1.b" {
            opt 4.2;
        }
    }

    multi {
        opt "just multi"
    }

    multi "special" class {
        num 3.14e0;
    }

    top-opt 3.1415926;

Assuming that `$cfg` is our [`Config::BINDish`](../../BINDish.md) instance, and by noting that method `get` is available on it via `$.top` attribute, we can have the following:

    $cfg.get: :multi => "opt"; # Get option "opt" from the nameless block multi, i.e. results in "just multi"
    $cfg.get: :multi("1") =>
                :subblk("level 1.a") =>
                    :subsubblk("level 2", "nesting") =>
                        "opt2"; # "π"

It is also possible to request multiple objects at once by passing a [`Positional`](https://docs.raku.org/type/Positional) as the final path value:

    $cfg.get(:foo<bar baz>); # Returns options "bar" and "baz" in block "foo"

Or another way to achieve the same result is to use a [`Code`](https://docs.raku.org/type/Code) object as the final path value:

    $cfg.get(foo => { "bar", "baz" });

In this case the return value of the code is coerced into a [`List`](https://docs.raku.org/type/List) and used as in the previous example. This also means that `$cfg.get(foo => { "bar" })` would return a single-element list consisting of *"bar"* value.

*Note.* The code object takes a single argument which is the last block object on the path. In the last example this would be the object representing block *"foo"*.

Apparently, there is no way for the method to distinguish block requests from option requests and there is no way to tell wether `:foo<name>` stands for option *"name"* in block *"foo"*, or is it for a block `foo "name" { }`? To make one's intentions clear a named argument `:block` can be used:

    $cfg.get(:foo<name>, :block);  # Would return a block object
    $cfg.get(:foo<name>, :!block); # Would return an option object;

`:!block` is the default. Similarly to options, blocks can be referenced with a string (for nameless ones), with a [`Positional`](https://docs.raku.org/type/Positional), or a [`Code`](https://docs.raku.org/type/Code) object.

Note that because a block is mostly useful for introspection whereas from options we would mostly require their values, method `get` has different return semantics for different requests. Thus, if a block has values on it like in the following example:

    serivce "api" {
        servers {
            "srv1.local";
            "srv2.local";
        }
    }

and the values are what we need then we'd have to request them explicitly:

    $cfg.get(:service<api> => :servers, :block).values; # ("srv1.local", "srv2.local")

Contrary, is we need to introspect an option object then we need to use `:raw` named argument with a request:

    $cfg.get(:foo<bar>, :raw);

*Note.* The actual nature of the returned option or block object may differ depedning on the conditions. See the Default Values section above.

Option lookup is done locally on the last block preceding the option reference in path. This behavior can be changed with explicit `:!local` argument causing the option to be looked upon in any nested block recursively. Note though that if the lookup fails then search for a default value is only done locally. I.e., if we have a config file like this:

    foo { bar { } }

And request for `:foo<fubar>`, a `Nil` will be returned even with the following pre-declaration:

    options => (
        :fubar => %( :in<bar>, :default(42) ),
    )

### `multi get(Pair:D :$option, *%c)`

Returns an option object defined by a path. Shortcut for `$blk.get($option, :!block, :raw, |%c)`.

### `multi get(Pair:D :$value, *%c)`

Returns an option value defined by a path. Shortcut for `$blk.get($value, :!block, :!raw, |%c)`.

### `multi get(Pair:D :$block, *%c)`

Returns a block object defined by a path. Shorcut for `$blk.get($block, :block, |%c)`.

SEE ALSO
========

[`Config::BINDish`](../../BINDish.md), [`Config::BINDish::AST`](../AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

