NAME
====

`role Config::BINDish::AST::Blockish` - interface of a generic block class

DESCRIPTION
===========

This role mostly implements basic block search capabilities provding interface for locating and pulling out various kinds of children objects.

METHODS
=======

### `multi find(:$block!, :$name, :$class, Bool :$local --> Config::BINDish::AST::Block)`

Similar to `find-all(:$block!, ...)` candidate but makes makes sure that only one block entry is found. It either returns the block instance found, or [`Nil`](https://docs.raku.org/type/Nil), or throws with [`Config::BINDish::X::Block::Ambiguous`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Block/Ambiguous.md) if more than one candidate found.

### `multi find(:$option!, Bool :$local --> Config::BINDish::AST::Option)`

Similar to the candidate for `:$block!`, but for options. Returns [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Option.md). Throws with [`Config::BINDish::X::Option::Ambiguous`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Option/Ambiguous.md).

### `block($block, *%p)`

A shortcut for `$node.find(:$block, |%p)`.

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

If `$raw` named argument is used then instead of payloads the method will return instances of [`Config::BINDish::AST::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Value.md).

Method `get`
------------

This is an umbrella method which provides a few ways of accessing configuration data.

### `multi get(Str:D $option, Bool :$raw, Bool :$local = True)`

By default returns `$option` value. With `:raw` argument will return corresponding [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Option.md) object. With `:!local` will search for the option recursively.

    $block.get("foo");        # Option "foo" value

### `multi get(Str:D :$option, Bool :$local = True)`

Returns an option object.

### `multi get(Str:D :$value, Bool :$local = True)`

Returns an option value. Note that `$value` must contain option keyword:

    $block.get: :value<foo>; # Option "foo" value

### `multi get(Str:D :$block, *%c)`

Finds and returns a block object. Named arguments in `%c` must be all the same as for the `block` method above.

### `multi get(Pair:D $path)`

***NOTE!** This interface is experimental and may change in the future versions of the module. Yet, if it ever be removed this won't happen without a deprecation cycle.*

This is the most advanced form of `get` method. It allows to find an option by its path. The path is defined as a nested structure of [`Pair`](https://docs.raku.org/type/Pair)s. For each `Pair` its key specifies a subblock within its parent block; value specifies an object within the subblock. In a pseudocode it looks like:

    $block => $subpath # Proceed to subpath under $block
    $block => $option  # Get option value from $block

Both key and value can be [`Pair`](https://docs.raku.org/type/Pair)s.

When key is a [`Pair`](https://docs.raku.org/type/Pair) then it is considered a block reference. Its key defines block type, its value defines block name and, possibly, class:

    :foo<bar> => ...; # find in `foo "bar" { ... }`
    :foo("bar", "baz") => ... # find in `foo "bar" baz { ... }`

When value is a [`Pair`](https://docs.raku.org/type/Pair) then it is considered the next step in the path what returns us recursively to the definition of the path above.

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

Assuming that `$cfg` is our [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md) instance, and by noting that method `get` is available on it via `$.top` attribute, we can have the following:

    $cfg.get: :multi => "opt"; # Get option "opt" from the nameless block multi, i.e. results in "just multi"
    $cfg.get: :multi("1") =>
                :subblk("level 1.a") =>
                    :subsubblk("level 2", "nesting") =>
                        "opt2"; # "π"

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

