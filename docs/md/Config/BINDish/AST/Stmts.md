# CLASS

`class Config::BINDish::AST::Stmts` - a transparent container of statements

# DESCRIPTION

This class has barely any other use but to serve as a temporary container for a set of other [`Config::BINDish::AST`](../AST.md) objects until they find their final parent. Instances of this class are *transparent* meaning that whenever such object is added to a node the operation will result in all children moved to the node and the `AST::Stmts` object being discarded.

An instance of `AST::Stmts` cannot have a parent. In fact, any attempt to use `set-parent` method will result in \<`Config::BINDish::X::StmtsAdopted` being thrown.

# METHODS

### `dismiss()`

This methods cleans up `@.children` to prevent accidental manipulation with any child after they are moved to their final parent node.

# SEE ALSO

  - [`Config::BINDish`](../../BINDish.md)

  - [`Config::BINDish::AST`](../AST.md)

  - [`README`](../../../../../README.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
