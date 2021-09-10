CLASS
=====

`Config::BINDish::AST` - the standard `Config::BINDish` AST tree representation

DESCRIPTION
===========

As a module `Config::BINDish::AST` defines all standard AST node classes used by [`Config::BINDish::Actions`](Actions.md) to build the resulting representation of the parsed configuration.

As a class `Config::BINDish::AST` is the base class for all other AST classes.

Labels
------

A little bit of special attention must be paid to labeling functionality of AST. Let's consider how an option is parsed:

    the-answer 42;

In the above example both `the-answer` and `42` are considered to be *values* and as such they result in two instances of [`Config::BINDish::AST::Value`](AST/Value.md). Both objects then become children of an [`Config::BINDish::AST::Option`](AST/Option.md) instance. Roughly, the parsed tree will look like:

    Option
     `---- Value
     `---- Value

To distinguish one value from another we can attach labels to them. So, the value representing option name will get tagged as *"option-name"*; and *42* will become *"option-value"*.

See methods `mark-as`, `labels`, `is-marked`, `child`, `children` below.

METHODS
=======

### `dup(*%twiddles)`

This method is close in its functionality to the standard Raku `clone` method, but adjusted for the needs of AST class family.

### `set-parent(Config::BINDish::AST::Node:D $parent)`

Sets AST instance parent node.

### `multi parent()`

Returns current parent node.

### `multi parent(Config::BINDish::AST:U \parent-type)`

Returns the closest parent node of type `parent-type`. For example, to get the enclosing block of a [`Config::BINDish::AST::Value`](AST/Value.md) one can do:

    $value.parent(Config::BINDish::AST::Block);

### `multi mark-as(*@labels)`

Sets labels for AST instance.

### `is-marked(Str:D $label --` Bool:D)>

Returns *True* if AST object is marked with `$label`.

### `labels()`

Returns a list of all AST object labels.

### `ast-name()`

Returns current node name, based on the node class name. If the name starts with *Config::BINDish::AST::* then this part is stripped off. Otherwise the class name is considered to be the name.

### `dump(Int:D :$level = 0 --` Str:D)>

Returns current node' string representation which consists of its `ast-name` and `gist`. The string would be indented by `$level` white spaces.

### `register-type(Str:D $ast-name, Mu \ast-type)`

Method registers an `ast-type` class under `$ast-name`. `new-ast` method (see below) can later create a node instance based on its registered name.

### `new-ast(Str:D $node-type, |profile --` Config::BINDish::AST:D)>

Creates a new instance of ast node based on its name. The name can be either a registered AST node name, see `register-type` method above; or a short name under `Config::BINDish::AST::` namespace. If no associated AST type object is found then a failure wrapped around [`Config::BINDish::X::AST::DoesnExists`](X/AST/DoesnExists.md) is returned.

For example, with the following statement:

    Config::BINDish::AST.register-type("MyAppNode", MyApp::Config::AST::Node);

it is then possible to:

    Config::BINDish::AST.new-ast("MyAppNode", :foo(42), :bar("The Answer")); # An instance of My::App::Config::AST::Node

For one of the standard AST nodes one can:

    Config::BINDish::AST.new-ast('Block', :name(...), :class(...), ...); # An instance of Config::BINDish::AST::Block

### `top-node(--> Config::BINDish::AST)`

Returns the topmost node, or, in other words, the root of the AST tree.

AST NODE CLASSES AND ROLES
==========================

Roles
-----

  * [`Config::BINDish::AST::Container`](AST/Container.md)

  * [`Config::BINDish::AST::Node`](AST/Parent.md)

Classes
-------

  * [`Config::BINDish::AST::Block`](AST/Block.md)

  * [`Config::BINDish::AST::Comment`](AST/Comment.md)

  * [`Config::BINDish::AST::Option`](AST/Option.md)

  * [`Config::BINDish::AST::NOP`](AST/NOP.md)

  * [`Config::BINDish::AST::Stmts`](AST/Stmts.md)

  * [`Config::BINDish::AST::TOP`](AST/TOP.md)

  * [`Config::BINDish::AST::Value`](AST/Value.md)

SEE ALSO
========

[`Config::BINDish`](../BINDish.md), [`Config::BINDish::Aactions`](Aactions.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

