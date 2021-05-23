NAME
====

`Config::BINDish::AST` - the standard `Config::BINDish` AST tree representation

DESCRIPTION
===========

As a module `Config::BINDish::AST` defines all standard AST node classes used by [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Actions.md) to build the resulting representation of the parsed configuration.

As a class `Config::BINDish::AST` is the base class for all other AST node classes.

ATTRIBUTES
==========

### [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Parent.md) `$.parent`

Points to the parent node. Will stay undefined for the `TOP` node.

METHODS
=======

### `set-parent(Config::BINDish::AST::Parent:D $parent)`

Sets `$.parent` attribute.

### `ast-name()`

Returns current node name, based on the node class name. If the name starts with *Config::BINDish::AST::* then this part is stripped off. Otherwise the class name is considered to be the name.

### `dump(Int:D :$level = 0)`

Dumps current node' string representation which consists of `ast-name` and `gist` and would be indented by `$level` white spaces.

### `register-type(Str:D $ast-name, Mu \ast-type)`

Method registers an `ast-type` class under `$ast-name`. `new-ast` method (see below) can later create a node instance based on its registered name.

### `new-ast(Str:D $node-type, |profile --` Config::BINDish::AST:D)>

Creates a new instance of ast node based on its name. The name can be either a registered AST node name, see `register-type` method above; or a short name under `Config::BINDish::AST::` namespace. If no associated AST type object is found then a failure wrapped around [`Config::BINDish::X::AST::DoesnExists`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/AST/DoesnExists.md) is returned.

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

  * [`Config::BINDish::AST::Container`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Container.md)

  * [`Config::BINDish::AST::Decl`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Decl.md)

  * [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Parent.md)

Classes
-------

  * [`Config::BINDish::AST::Block`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Block.md)

  * [`Config::BINDish::AST::Comment`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Comment.md)

  * [`Config::BINDish::AST::Option`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Option.md)

  * [`Config::BINDish::AST::NOP`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/NOP.md)

  * [`Config::BINDish::AST::TOP`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/TOP.md)

  * [`Config::BINDish::AST::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Value.md)

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::Aactions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Aactions.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

