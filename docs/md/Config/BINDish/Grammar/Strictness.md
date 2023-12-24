# CLASS

`Config::BINDish::Grammar::Strictness` - strict mode options

# DESCRIPTION

This class defines what parts of the parser should operate in strict mode. See [ATTRIBUTES](#ATTRIBUTES).

The most simple way to initialize an instance of this class is to coerce it from a [`Bool`](https://docs.raku.org/type/Bool) value:

``` 
Config::BINDish::Grammar::Strictness(True); # All strict
```

From the perspective of creating a new grammar it would be done as:

``` 
Config::BINDish::Grammar.parse(..., :strict);   # All strict
Config::BINDish::Grammar.parse(..., :!strict);  # All non-strict
```

# ATTRIBUTES

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.syntax = False`

When set the parser will require a semi-colon (`;`) after all statements. Otherwise semi-colon is optional after block's closing curly brace, and after an option if it is followed by a closing brace. The following example is ok when syntax is non-strict:

``` 
block {
    option "foo"
}
```

Otherwise it has to be like this:

``` 
block {
    option "foo";
};
```

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.options = False`

This attribute determines if all options have to be explicitly pre-declared.

See method `declare-options` in [`Config::BINDish::Grammar`](../Grammar.md).

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.blocks = False`

This attribute determines if all block types have to be explicitly pre-declared.

See method `declare-blocks` in [`Config::BINDish::Grammar`](../Grammar.md).

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.warnings = True`

If set the the grammar will issue warnings when it suspects a problem. For example, a warning will be printed if a hash is used to initialize grammar's `%.options` or `%.blocks` attributes:

``` 
Config::BINDish.new: options => { :op1<op> => { ... } };
```

Because by default Raku uses hashes with [`Str`](https://docs.raku.org/type/Str) keys, `:op1<op>` will be coerced and instead a [`Pair`](https://docs.raku.org/type/Pair), representing option `op` ID and keyword, the grammar will find a string *"op1\\top"* which is an invalid keyword.

# SEE ALSO

  - [`Config::BINDish`](../../BINDish.md)

  - [`Config::BINDish::Grammar`](../Grammar.md)

  - [`README`](../../../../../README.md)

  - [`INDEX`](../../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../../LICENSE) file in this distribution.
