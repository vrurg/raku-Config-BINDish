NAME
====

`role Config::BINDish::AST::Parent` - a parent node interface and implementation

DESCRIPTION
===========

This role is responsible for holding and manipulating children nodes. It is also provides the primary interface of seeking and obtaining data withing AST tree.

ATTRIBUTES
==========

### [`Config::BINDish::AST:D`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md) `@.children`

The actual list of children nodes.

METHODS
=======

### `dump(Int:D :$level = 0)`

Dumps the subtree held under `self`.

### `multi add(Config::BINDish::AST:D $child --` Config::BINDish::AST:D)>

Adds a new `$child` object to the children. 

Returns `self`.

### `multi add(Str:D $node-type, |profile --` Config::BINDish::AST:D)>

Creates a new node of `$node-name` name. Then see the previous candidate.

The `profile` capture is passed to the new node constructor.

### `multi find-all(&matcher, Bool :$local --> Seq:D)`

This method iterates over children and lazily gathers those for which `&matcher($child)` is *True*. Unless `$local` is set the method also iterates children recursively.

### `multi find-all(:$block!, :$name, :$class, Bool :$local --> Seq:D)`

This candidate is kind of a shortcat to find all blocks of type `$block` and, optionally, with `$name` and `$class` specified. For example:

    $cfg-bindish.top.find-all(:block<network>)

will return a lazy [`Seq`](https://docs.raku.org/type/Seq) of all `network` blocks. Or:

    $cfg-bindish.top.find-all(:block<network>, :name(/^office <.wb>/))

will return all `network` blocks where names start with *office* word.

### `multi find-all(:$option!, Bool :$local --> Seq:D)`

Another shortcut candidate to find all options declared with `$option`. For example:

    $cfg-bindish.top.find-all(:option(/'-gw' $/))

will return a lazy [`Seq`](https://docs.raku.org/type/Seq) of all options in the configuration whose name ends with *-gw*. Note that the sequence will contain objects of [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Option.md) type, not their values.

### `multi find(:$block!, :$name, :$class, Bool :$local --> Config::BINDish::AST::Block)`

Similar to `find-all(:$block!, ...)` candidate but makes makes sure that only one block entry is found. It either returns the block instance found, or [`Nil`](https://docs.raku.org/type/Nil), or throws with [`Config::BINDish::X::Block::Ambiguous`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Block/Ambiguous.md) if more than one candidate found.

### `multi find(:$option!, Bool :$local --> Config::BINDish::AST::Option)`

Similar to the candidate for `:$block!`, but for options. Returns [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Option.md). Throws with [`Config::BINDish::X::Option::Ambiguous`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Option/Ambiguous.md).

### `block($block, *%p)`

A shortcut for `$node.find(:$block, |%p)`.

### `blocks($block, *%p)`

A shortcut for $<$node.find-all(:$block, |%p)>.

### `option($option, Bool :$local = True, *%p)`

A shortcut for `$node.find(:$option, :$local, |%p)`. Note that `$local` is *True* by default as this is the most anticipated mode of operation. With `:!local` it's still possible to do a recursive search for a unique option instance.

### `options($option, Bool :$local = True, *%p)`

A shortcut to `$node.find-all(:$option, :$local, |%p)`. Note that `$local` is also set to *True* by default, as for `option` method above. This is still meaningful because a block may contain multiple options of the same name.

### `value($option, Bool :$local = True, *%p)`, `values($option, Bool :$local = True, *%p)`

This two methods are similar to `option` and `options` methods above except that they return not options but payloads of their `$.value` attributes.

Method `get`
------------

This is an umbrella method which provides a few ways of accessing configuration data.

### `multi get(Str:D $option, Bool :$raw, Bool :$local = True)`

By default returns `$option` value. With `:raw` argument will return corresponding [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Option.md) object. With `:!local` will search for the option recursively.

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

Assuming that `$cfg` is our [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md) instance, and by noting that method `get` is available on it via `$.top` attribute, we can have the following:

    $cfg.get: :multi => "opt"; # Get option "opt" from the nameless block multi, i.e. results in "just multi"
    $cfg.get: :multi("1") =>
                :subblk("level 1.a") =>
                    :subsubblk("level 2", "nesting") =>
                        "opt2"; # "π"

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

