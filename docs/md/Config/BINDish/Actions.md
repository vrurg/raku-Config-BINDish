# CLASS

`Config::BINDish::Actions` - default actions for [`Config::BINDish::Grammar`](Grammar.md)

# DESCRIPTION

This class is the default to be used for parsing configs. It builds [`Config::BINDish::AST`](AST.md) tree representation of a config data which is then provided to application code via [`Config::BINDish`](../BINDish.md) attribute `$.top`. The tree can be used to fetch required configuration data, see [`Config::BINDish::AST`](AST.md).

# METHODS

Most of the methods correspond to named rules in [`Config::BINDish::Grammar`](Grammar.md). In this section only utility methods are documented.

### `make-container(Config::BINDish::Grammar::Value:D $val)`

Method creates a new instance of [`Config::BINDish::AST::Value`](AST/Value.md) from its grammar counterpart.

### `enter-parent(Config::BINDish::AST::Node:D $inner --` Config::BINDish::AST::Node:D)\>

### `enter-parent(Config::BINDish::AST::Node:U $inner, |profile --` Config::BINDish::AST::Node:D)\>

Method is invoked when a new [`Config::BINDish::AST::Node`](AST/Node.md) is to be created. For example, this class uses it when creates the `TOP` node and each time a new block node is created. [`Config::BINDish::Expandable`](Expandable.md) also uses this method for another kinds of nodes.

If `$inner` is an undefined typeobject then the method first creates an instance of it using method `new` and using `profile` as its arguments:

``` 
$inner.new(|profile)
```

Method sets `$*CFG-INNER-PARENT`.

### `inner-parent()`

Returns the innermost parent node.

# SEE ALSO

  - [`Config::BINDish`](../BINDish.md)

  - [`Config::BINDish::Grammar`](Grammar.md)

  - [`README`](../../../../README.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
