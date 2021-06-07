NAME
====

`class Config::BINDish::AST::Node` - a parent node interface and implementation

DESCRIPTION
===========

This role is responsible for holding and manipulating children nodes. It is also provides the primary interface of seeking and obtaining data withing AST tree.

METHODS
=======

### `dump(Int:D :$level = 0)`

Dumps the subtree held under `self`.

### `multi add(Config::BINDish::AST:D $child --` Config::BINDish::AST:D)>

Adds a new `$child` object to the children. 

Returns `self`.

### `multi add(Config::BINDish::AST::Stmts:D $child --` Config::BINDish::AST:D)>

This candidate pulls all [`Config::BINDish::AST::Stmts`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Stmts.md) children and re-plants them under `self`. When all children moved method `dismiss` is invoked on `$child`.

Returns `self`.

### `multi add(Str:D $node-type, |profile --` Config::BINDish::AST:D)>

Creates a new node of `$node-name` name. Then see the previous candidate.

The `profile` capture is passed to the new node constructor.

### `multi children()`

Returns all children objects.

### `multi children(Str:D $label)`

Returns all children marked with `$label`.

### `child(Str:D $label)`

Returns a single child marked with `$label`. If there are multiple children with the label then a [`Failure`](https://docs.raku.org/type/Failure) returned wrapped around `Config::BINDish::X::OneTooMany`.

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

will return a lazy [`Seq`](https://docs.raku.org/type/Seq) of all options in the configuration whose name ends with *-gw*. Note that the sequence will contain objects of [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Option.md) type, not their values.

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md), [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

