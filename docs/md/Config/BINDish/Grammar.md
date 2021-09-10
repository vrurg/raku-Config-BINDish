NAME
====

`Config::BINDish::Grammar` - the central class of everything in `Config::BINDish`

DESCRIPTION
===========

This class is responsible for the actual parsing of the configuration. It is not recommended for direct use. [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md) `read` method must be used instead.

The class inherits from the standard [`Grammar`](https://docs.raku.org/type/Grammar) class.

ATTRIBUTES
==========

Some attributes are declared with help of [`AttrX::Mooish`](https://modules.raku.org/dist/AttrX::Mooish). For `lazy` attributes it means that method `build-attribute-name` is used to get the initial value. These methods can be overridden by extensions if necessary.

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.flat`

If set this attribute expects blocks to be flattened down. I.e. whenever a block has a duplicate declaration in the config the later declaration must be applied on top of the first one. This doesn't change grammar's behavior but rather serves as a note for the actions class to take care of the situation. One way or another, if this attribute is *True* then the user expects a single block `foo "bar"` representation to exists after the following sample is parsed:

    foo "bar" { fubar 1; }
    baz { }
    foo "bar" { fubar 2; fubaz 3.14; }

How the options are dealt with is the sole prerogative of the actions implementation. [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Actions.md) re-delegates handling of flattening to the underlying [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST.md) class. It, in turn, will overwrite earlier option declarations with latter ones. So, when one queries for `fubar` the value returned will be *2*.

See [$*CFG-FLAT-BLOCKS](#$*CFG-FLAT-BLOCKS).

### [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Strictness.md) `$.strict = False`

Defines what strictness modes are activated. See [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Strictness.md).

### `@.prop-keys`

*Lazy*. Defines the types of statements supported by pre-declaration. Currently it is set to *block* and *option*. But extensions can add their own types via overriding `build-prop-keys` method.

### [`Hash`](https://docs.raku.org/type/Hash)`[`[`Config::BINDish::Grammar::StatementProps:D`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/StatementProps.md)`]` `%.props`

*Lazy*. Registry of all pre-declared statement properties. The first level keys of the hash are values in `@.prop-keys`, the second level keys are statement IDs.

### [`SetHash`](https://docs.raku.org/type/SetHash) `%.keywords`

*Lazy*. Registry of all registered keywords. Keys are the values in `@.prop-keys`. Values are `SetHash`'es of pre-declared keywords. The purpose of the attribute is to let code know if a keyword is used by a pre-declaration.

### `%.prop-relations`

*Lazy*. First level keys are IDs of blocks ever mentioned with `in` key in statement pre-declaraions. For example:

    Config::BINDish.new: blocks => ( :srv-cloud<service> => { ... },
                                     :srv-local<service> => { ... }
                         ),
                         options => ( :loc-url<location> => { :in<srv-cloud> } );

`srv-cloud` will become a key on `%.prop-relations`, contrary to `srv-local` which is not referenced by any pre-declaration.

The second level keys are types listed in `@.prop-keys`.

The third level keys of the hash are keywords allowed in the block. In the above example there will be just one key: `location` under `option`. It's value will be properties object of the option with ID `loc-url`.

Note that the keyword, not the ID, is used in this case. This is because a keyword must be unique per block per statement type. I.e. we can have a block `location`, and an option `location`. But we can't have two different `location` options.

### [`Pair:D`](https://docs.raku.org/type/Pair) `@.blocks`

List of user-defined blocks. Passed to `declare-blocks` method at object construction time.

See [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/BlockProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

### [`Pair:D`](https://docs.raku.org/type/Pair) `@.options`

List of user-defined options. Passed to `declare-options` method at object construction time.

See [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/OptionProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

### `%.reserved-opts`

Keys of this hash are names of options which are reserved for `Config::BINDish` own use. An extension module can add more keys to the hash if it needs to.

### Int:D `$.line-delta = 0`

Contains the delta to be subtracted from the actual line number when it is reported to the user. For example, if set to 2 and the actual location is at line 10 then the user will be reported with number 8. Used by `#line` directive.

DYNAMIC VARIABLES
=================

The grammar declares and uses a set of dynamic variables to pass certain information between its rules, tokens, methods, and the actions object.

### `$*CFG-GRAMMAR`

The primary grammar object. Due to the way the [`Grammar`](https://docs.raku.org/type/Grammar) is implemented `self` does not always point to the same object created by the initial `parse` method. These instances are not full clones of the original grammar and do not inherit all attribute values from it. For this reason when access to the user-set attributes is needed the original grammar is better be easily available.

### `$*CFG-CTX`

Current block or option context.

### `$*CFG-PARENT-CTX`

Parent block context.

### `$*CFG-AS-INCLUDE`

If set to *True* then it means that the current grammar is parsing included source.

### `$*CFG-FLAT-BLOCKS`

Set to `$.flat` attribute value.

### `$*CFG-INNER-PARENT`

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::Node`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/Node.md).

### `$*CFG-TOP`

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::TOP`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/AST/TOP.md).

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-VALUE`

Must be provided directly or indirectly by any rule or token invoking the `<value>` token. This variable will be set to a [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) instance created by `set-value` method.

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-KEYWORD`

Set by `<keyword>` token. The value stored will be of type [`Str`](https://docs.raku.org/type/Str) and have type name *"keyword"*.

### `$*CFG-BLOCK-TYPE`, `$*CFG-BLOCK-NAME`, `$*CFG-BLOCK-CLASS`

All three are of [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) type. When the following example is parsed:

    foo "bar" baz { }

The variables will be set to:

  * type: "foo" of [`Str`](https://docs.raku.org/type/Str), type-name *"keyword"*

  * name: "bar" of [`Str`](https://docs.raku.org/type/Str), type name *"dq-string"*

  * class: "baz" of [`Str`](https://docs.raku.org/type/Str), type name *"keyword"*

Note that the name could be of any value, supported by the grammar. If an extension adds a new value type then the type can also be used as a type name. Say, with [`Config::BINDish::INET`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/INET.md) loaded one can have the following valid declaration:

    IP 192.168.1.42 { }

For which the name will be set to type `IP::Addr`, type-name *"IPv4"*.

### `$*CFG-BLOCK-ERR-POS`

This variable is set to a [`Match`](https://docs.raku.org/type/Match) object pointing at the location where current block declaration starts. Can be used for error reporting.

### `$*CFG-SPECIFIC-VALUE-SYM`

Set by the grammar whenever a specific value type is expected. See more details in [value-sym](#value-sym) section below.

### `$*CFG-BACKTRACK-OPTION`, `$*CFG-BACKTRACK-BLOCK`

These variables are set by corresponding `backtrack-*` method to indicate the context in which `leave-*` methods are called. In other words, if `!$*CFG-BACKTRACK-OPTION` is *True* when `leave-option` is invoked then an option has been successfully parsed.

METHODS
=======

### `set-value(Mu \type, *%value)`

This methods creates a new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) object and assigns it to `$*CFG-VALUE`. Takes value's type object as its single positional parameter. Type name and payload are passed as the only named argument of the method call. Here is how a single-quoted string is handled by the grammar:

    token sq-string {
        \' ~ \' $<string>=<.qstring("'")>
        {
            self.set-value: Str, :sq-string($<string>)
        }
    }

In this example the new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Value.md) object will be created with payload set from `$<string>`, type name set to *"sq-string"*, and type set to [`Str`](https://docs.raku.org/type/Str).

### `set-line-relative(Int:D $from-line, Int:D :$to-line = self.line(:absolute))`

Sets `$.line-delta` as a difference between `$from-line` to `$to-line` so that, when a line number is reported at some point in time after a call to this method, the user will see `$reported-line - ($to-line - $from-line + 1))`.

### `set-file($file)`

Sets the file name to be reported to the user in messages.

### `file()`

Returns file name to be reported in messages.

### `line(Bool :$absolute = False)`

Returns either a line number to be reported in messages; or the absolute line number of the currently parsed buffer.

### `submethod setup-BINDish`

When the grammar is instantiated it iterates over all of its parents and roles and invokes each unique `setup-BINDish` submethod it finds. While it may seem to look as a duplicate of `TWEAK`, the purpose of using this approach is to eliminate the differences in handling of submethods by Raku versions 6.c/d and 6.e.

See also [Pre-declaration](#Pre-declaration) section.

### `multi reserve-keywords(Str:D $what, @keywords)`

### `multi reserve-keywords(*%what-keywords)`

Registers a list of keywords as reserved. `$what` is statement type for which keywords are registered; must be one of `@.prop-keys` values.

    $*CFG-GRAMMAR.reserve-keywords: "option", <foo bar>;
    $*CFG-GRAMMAR.reserve-keywords: option => <foo bar>,
                                    block  => <bar baz>;

### `multi is-reserved(Str:D $what, Str:D $keyword)`

### `multi is-reserved(*%p where *.elems == 1)`

Returns *True* is `$keyword` is registered for statement type `$what`. The second for is a convenience one, it accepts only a single named parameter with name being the statement type. The following two line are equivalent:

    $*CFG-GRAMMAR.is-reserver: 'option', 'foo';
    $*CFG-GRAMMAR.is-reserver: :option<foo>;

### `proto statement-props(Str:D $what)`

Returns pre-declaration properties class depending on the value of `$what`. The candidates provided by the core only support *'option'* and *'block'* and return [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/OptionProps.md) or [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/BlockProps.md) respectively. An extension can add own candidate if it introduces additional statement type.

### `declare-statement(Str:D $what, Any:D $id = self.autogen-id, $keyword where Str:D | Bool, :%props, Bool :$cleanup = True)`

This is a low-level statement pre-declaration registration method. It creates a properties object with the class returned by `statement-props` method for statement type `$what` and using `%props` as constructor initialization profile. `$id` and `$keyword` are also used as initialization profile keys.

If `$keyword` parameter is a [`Bool`](https://docs.raku.org/type/Bool) value then it is set to `$id` value. This is done to provide support for `:foo =` { ... }> pre-declaration syntax where `:foo` represents both ID and keyword.

Parameter `$cleanup` specifies if `$.prop-relations` attribute must be reset and rebuilt. It is unlikely a user would ever need it to be *False*.

### `multi declare-block(Any:D $id, Str:D $keyword, %props, Bool :$cleanup = True --> BlockProps:D)`

### `multi declare-block(Any:D $id, Str:D $keyword, Bool :$cleanup = True, *%props --> BlockProps:D)`

### `multi declare-block(Pair:D $identity, %props, Bool :$cleanup = True --> BlockProps:D)`

### `multi declare-block(Str:D $keyword, %props, Bool :$cleanup = True --> BlockProps:D)`

### `multi declare-block(Str:D $keyword, Bool :$cleanup = True, *%props --> BlockProps:D)`

### `multi declare-block(*%params --> BlockProps:D)`

This method registers a single block. Parameters:

  * `$id` – block ID

  * `$keyword` – block keyword

  * `$identity` - a [`Pair`](https://docs.raku.org/type/Pair) where the key is `$id`, and the value is `$keyword`

  * `%props` – hash of block properties; see [Pre-declaration](#Pre-declaration)

  * `$cleanup` – see `declare-statement` method

  * `%params` - hash of named parameters for `declare-statement`

Basically, all this method does it turns its parameters into named arguments for `declare-statement` and calls it as `self.declare-statement('block', |%params)`.

### `multi declare-blocks(@blocks, Bool :$cleanup = True --> Nil)`

### `multi declare-blocks(%blocks, Bool :$cleanup = True --> Nil)`

Pre-declare blocks. `@blocks` is expected to be a list of [`Pair`](https://docs.raku.org/type/Pair) objects, as explained in [Pre-declaration](#Pre-declaration) section.

### `multi declare-option(Any:D $id, Str:D $keyword, %props, Bool :$cleanup = True --> OptionProps:D)`

### `multi declare-option(Pair:D $identity, %props, Bool :$cleanup = True --> OptionProps:D)`

### `multi declare-option(Str:D $keyword, %props, Bool :$cleanup = True --> OptionProps:D)`

### `multi declare-option(Str:D $keyword, Bool :$cleanup = True, *%props --> OptionProps:D)`

### `multi declare-option(*%params --> OptionProps:D)`

This method registers a single option. Parameters:

  * `$id` – option ID

  * `$keyword` – option keyword

  * `$identity` - a [`Pair`](https://docs.raku.org/type/Pair) where the key is `$id`, and the value is `$keyword`

  * `%props` – hash of option properties; see [Pre-declaration](#Pre-declaration)

  * `$cleanup` – see `declare-statement` method

  * `%params` - hash of named parameters for `declare-statement`

Basically, all this method does it turns its parameters into named arguments for `declare-statement` and calls it as `self.declare-statement('option', |%params)`.

### `multi declare-options(@options)`

### `multi declare-options(%options)`

Pre-declare options. `@options` is expected to be a list of [`Pair`](https://docs.raku.org/type/Pair) objects, as explained in [Pre-declaration](#Pre-declaration) section.

### `autogen-id()`

Returns a unique string to be used as a statement identifier.

### `enter-ctx(Value:D :$keyword, Str:D :$type, *%profile)`

Creates a new [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Context.md) object. Returns the new context, which is also stored into `$*CFG-CTX`.

This method expects `$*CFG-PARENT-CTX` to be set to the parent context instance, and `$*CFG-CTX` to be undefined. Normally a rule which plans to create a new context must have the following two lines in it:

    :my Context:D $*CFG-PARENT-CTX = $*CFG-CTX;
    :temp $*CFG-CTX = Nil;

Method throws `Config::BINDish::X::Parse::ContextOverwrite` if `$*CFG-CTX` is already set.

If `id` key in `%profile` is undefined then the method tries to guess it based on the `$keyword`. If it has at least one pre-declaration (i.e. it is recorded in `%.keywords`), then its properties are looked up either on enclosing block, or on `.ANYWHERE` block (see `%.prop-relations`). If neither lookup succeeds then it is assumed that the keyword cannot be used in the current block and `Config::BINDish::X::Parse::Context` is thrown.

If the `$keyword` is not pre-declared then the method uses `autogen-id` method to produce a new unique ID for the statement. Note that for two subsequent statements of the same type used within the same block two different IDs would be produced in this case.

### `backtrack-option()`

A callback method invoked by `statement:sym<option>` rule if it fails to parse a keyword statement as an option. This does not necessarily mean that there was a syntax error in the configuration source. It could be just a normal backtracking.

Set `$*CFG-BACKTRACK-OPTION` to *True* and invokes `leave-option` method.

### `backtrack-block()`

Similar to `backtrack-option` method above but for block declarations.

Sets `$*CFG-BACKTRACK-BLOCK` to *True* and invokes `leave-block` method.

### `leave-option()`

Invoked when leaving option context.

### `leave-block()`

Invoked when leaving block context.

### `validate-option()`

Validates currently being parsed option based on its keyword. Uses pre-set variables [`$*CFG-KEYWORD`](#$*CFG-KEYWORD) and [`$*CFG-VALUE`](#$*CFG-VALUE).

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/ValueType.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-block()`

Validates currently being parsed block based on its keyword (type), name, and, possibly, class. Uses pre-set variables [`$*CFG-BLOCK-TYPE`](#$*CFG-BLOCK-TYPE), [`$*CFG-BLOCK-NAME`](#$*CFG-BLOCK-NAME), [`$*CFG-BLOCK-CLASS`](#$*CFG-BLOCK-CLASS). If block passes the validation then a new block context is pushed onto the context stack.

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ExtraPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/ExtraPart.md), [`Config::BINDish::X::Parse::MissingPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/MissingPart.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-value()`

Makes sure a value can be used in the current context. Uses variable [`$*CFG-VALUE`](#$*CFG-VALUE).

Can throw [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/ValueType.md).

### `multi method panic(Str:D $msg)`

Throws [`Config::BINDish::X::Parse::General`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/X/Parse/General.md) with message `$msg`.

### `multi method panic(Config::BINDish::X::Parse:U \exception, Str $msg?, *%profile)`

Creates an object of type `exception` using `%profile` as named arguments for constructor and throws it. If $msg is specified then it is added to the profile as named argument `:$msg`.

Both `panic` methods also pass the grammar object they're invoked upon as `cursor` named argument to provide the exception instance with error location and other useful information.

### `include-source(IO:D(Str:D $file, Match:D $cursor --` Str:D)>

This method provides source configuration to be included with `include` option. The default implementation tries to read `$file`. If it can't then either of two exceptions are thrown:

  * `Config::BINDish::X::FileNotFound` if `$file` doesn't exists

  * `Config::BINDish::X::FileOp` if `$file` is unreadable

GRAMMAR ELEMENTS
================

Rules and tokens listed in this section are the ones considered public API of this module. Those not listed here but implemented by the grammar are considered implementation detail and can be changed or removed any time without prior notice.

Description provided here would mostly be rather succinct. Checking with the grammar source is the most correct way of understanding it.

Rules And Tokens
----------------

### `rule TOP`

See [`Grammar`](https://docs.raku.org/type/Grammar).

Pushes *"TOP"* context onto the stack and invokes `statement-list`.

### `token enter-TOP`

Does nothing, used as anchor for [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Actions.md).

### `rule statement-list`

Used in the global and block contexts.

### `proto statement`

Currently defined statements are (as named within `:sym<...>` postfix):

  * comment

  * value

  * option

  * block

  * empty

### `token statement-terminator`

Matches a statement terminator. Doesn't take the current strictness mode into account and tries matching as if non-strict syntax mode is used.

### `token statement-terminate`

A wrapper around `statement-terminator` which validates it against the current syntax strictness mode.

### `token block-head`

Parses the block type keyword. Sets [`$*CFG-BLOCK-TYPE`](#$*CFG-BLOCK-TYPE).

### `token block-name`

Parses the block name. Sets [`$*CFG-BLOCK-NAME`](#$*CFG-BLOCK-NAME).

### `token block-class`

Parses the block name. Sets [`$*CFG-BLOCK-CLASS`](#$*CFG-BLOCK-CLASS).

### `token block-body`

Validates the block and sets the current block context.

### `C-comment`, `CPP-comment`, `UNIX-comment`

Three types of comments

### `keyword`

Parses a keyword which is defined as an alpha-numeric identifier starting and ending with a word boundary. Sets [`$*CFG-KEYWORD`](#$*CFG-KEYWORD).

### `token dq-string`, `token sq-string`

Double- and single-quoted strings. The standard grammar and actions do not care about the exact nature of a string. But extensions could adjust their behavior based on the string type. For example, [`Config::BINDish::Expandable`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Expandable.md) implements macro expansion for double-quoted strings only.

### `proto token value`

Umbrella-rule for all value types. If you plan an extension for a new value type then this is where you plug it into.

The following value types are currently implemented, listed as named within `:sym<...>` postfix:

  * string

  * keyword

  * num

  * rat

  * int

  * bool

Named captures
--------------

Some named captures are also considered public API.

### `$<err-pos>`

Records the location to which call of method `panic` should be bound. In other words, if the location within a rule body where we make the decision about syntax validity is different from the location where the user would understand it best then `panic` should be invoked as:

    $<err-pos>.panic: X::Parse::AError, ...;

For example, we parse an option like:

    pi 3.1415926;

When all the information we need to validate it is collected our grammar points at the position right after the terminating semi-colon. If we do `self.panic(...)` then the error message look kind of the following:

    Option pi cannot be used in block...
      at line N
        pi 3.1415926;⏏

But with `$<err-pos>.panic(...)` it would rather be:

    Option pi cannot be used in block...
      at line N
        ⏏pi 3.1415926;

Which certainly makes more sense to the user.

### `$<option-name>`, `$<option-value>`

Point to parsed option name and value [`Match`](https://docs.raku.org/type/Match)es.

### `$<block-type>`

Points to parsed block type [`Match`](https://docs.raku.org/type/Match) object.

### `$<string>`

Points to actual string body of a stringy value. I.e. for *what "The answer is 42"* this capture will be a [`Match`](https://docs.raku.org/type/Match) object pointing at *The answer is 42* part of the source, quotes excluded.

GRAMMAR OPERATION
=================

Pre-declaration
---------------

*DISCLAIMER. I don't like the term "pre-declaration", but really can't come up with something better so far. Ideas are welcome!*

In the default mode operation the grammar accepts any blocks and options in a config file as long as the adhere to the syntax requirements. But often it is desirable to constrain the set of accepted block/option keywords. And even more often it is necessary to restrict certain syntax rules applied to them.

For example, for options it would make sense to restrict acceptable types of their values; actually, sometimes this applies to blocks too. For blocks we may need to specify requirements for the name and class parts to be used or not.

Another useful property of options and blocks is the context where they're allowed. By context the current grammar assumes the current enclosing block.

Let's consider a network configuration file where we use `host` and `lan` blocks and some network-related options.

*NOTE* that the following example requires [`Config::BINDish::INET`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/INET.md) module to be used.

    ip 192.168.1.2; // Error, we don't know the host to apply this ip to
    lan { # Error, a LAN must be given a name
    }
    lan "office" {
        network 192.168.42.0/24;
    }
    lan 192.168.1.0/24 {
        name "Data Center";
        ip 192.168.1.13; // Error, only a host can have an address
        host "gw" {
            ip 192.168.1.1; # This is default ip on the lan
            interface "outside" {
                ip 1.2.3.4/24;
                gw 1.2.3.1;
            }
        }
    }
    host "rambler" { // Error, a host can only belong to a lan
        ip "dhcp-pool"; // Good try, but – no, this is an error too!
        free-form "with some text"; # This is an error if the option is not pre-declared and strict mode is in effect
    }

Next in this section we will find out how to tell the grammar about the constraints we'd like to apply. Keep in mind that this section talks about options and blocks. And that any 3rd party extension module can introduce their own kinds of statements and use their own approach to their pre-declaration.

Statement pre-declaration consist of two parts:

  * statement descriptor which consists of its globally unique ID and a keyword

  * properties defining the actual constraints

There are also two ways to pre-declare:

  * via initializing `@.blocks` and `@.options` attributes with lists of [`Pairs`](https://docs.raku.org/type/Pairs) per each statement

  * via using `declare-` family of grammar methods

As a matter of fact, the grammar is using the attributes to eventually pass them to corresponding `declare-blocks` or `declare-options` methods in `setup-BINDish` submethod. This is also the recommended way for a 3rd party extension, would it need to utilize pre-declaration. But from the user perspective it is preferable to use the first way:

    my $cfg = Config::BINDish.new: blocks => (...), options => (...);

### Statement Pre-declaration Syntax

As it was stated before, blocks and options are pre-declared by pairs. For each [`Pair`](https://docs.raku.org/type/Pair) its key is statement descriptor, and its value is a hash of statement properties. The most generic statement pre-declaration would look like the following example:

    :id1<foo> => { :prop1(...), :prop2(...), ... }

The particular properties will be listed later in this section. For now let's focus on the descriptor.

### Statement Descriptor

There is a reason for the descriptor to consist of two elements. If we consider an option, its keyword might not be unique across config, but it can have different meaning within different blocks. Often it would mean different value types allowed for use too:

    lan "Data Center" {
        server "microservices.my.net" {
            location "Room C3, Rack 1234";
        }
        service "monitoring" {
            location https://nagios.local;
        }
    }

As you can see here, even though `location` keyword is used within both `server` and `service` blocks, it represents different options of which one specifies a physical location, and another is for a network location. Use of unique IDs allows the parse to distinguish them. In terms of creating an instance of `Config::BINDish` it would look like this:

    my $cfg = Config::BINDish.new: ...,
                options => (
                    :loc-phys<location> => { ... },
                    :loc-url<location> => { ... }
                );

But what if we actually don't need those IDs? In this case they can be omitted:

    my $cfg = Config::BINDish.new: ...,
                options => (
                    location => { ... },
                    location => { ... }
                );

When this notation is used the grammar will auto-generate unique IDs for each statement to still be able to distinguish one declaration from another. But `Config::BINDish::X::DuplicateKeyword` would be thrown if we attempt to use both variants in the same block.

Another case is when we know that statement's keyword is inherently unique. In the above example we can say this about the `server` and the `service` blocks. It would be OK to use IDs which match respective keywords. To do so a boolean [`Pair`](https://docs.raku.org/type/Pair) notation can be used to declare the blocks:

    my $cfg = Config::BINDish.new: ...,
                blocks => (
                    :server => { ... },
                    :service => { ... },
                );

The above is equivalent to `:server<server>` and `:service<service>` notations.

### Statement Properties

Properties of a statement pre-declaration are specified as keys of a hash. For example, the last example of the previous section can be written as:

    my $cfg = Config::BINDish.new: ...,
                blocks => (
                    :server => { :named },
                    :service => { :named },
                );

Detailed descriptions of each key follows.

#### `in`

This key specifies a set of block IDs where use of the statement is allowed. If a block is not listed in this key then the statement can't be used in that block.

    my $cfg = Config::BINDish.new: ...,
                blocks => (
                    :server => { :named },
                    :service => { :named },
                ),
                options => (
                    ip => { :in<server host> },
                    location => { :in<service> },
                );

With the above declaration:

    server "gw" {
        ip 192.168.42.1;
    }
    service "nagios" {
        ip 192.168.42.13; # Error, only location can be used here
        location https://nagios.local;
    }

Note how we use `host` alongside with `server` to pre-declare `ip`. This is not an error as the grammar will auto-vivify block pre-declaration for us. It will have both ID and keyword set to `host`. We can late re-declare it with non-default properties. If we do so the re-declaration will lost its *auto-vivified* status and any subsequent re-declaration will become an error.

#### `type`

This key allows to constrain value type which can be used for values of the statement. This key is used as RHS of [smartmatch](https://docs.raku.org/language/operators#index-entry-smartmatch_operator) operator.

    my $cfg = Config::BINDish.new: ...,
                options => (
                    multiplier => { :in<measurements>, :type(Num | Rat) },
                    ip => { :in<server>, type => IP::Addr },
                );

Because value validation takes place in a context where `$*CFG-VALUE` is available, it is even possible to do things like:

    my $cfg = Config::BINDish.new: ...,
                blocks => (
                    :srv-ph<server> => { :in<datacenter>, :named }, # A physical server
                    :srv-vm<server> => { :in<vm-cluster>, :named }, # A VM server
                ),
                options => (
                    location => { :in<srv-ph>, type => { $_ ~~ Stringy && $*CFG-VALUE.payload.contains('Rack') },
                    location => { :in<srv-vm>, type => { $_ ~~ Stringy && $*CFG-VALUE.payload.contains('Cluster') },
                );

#### `type-name`

Value type name elaborates on the exact meaning of a value. For example, a value can have Raku [`Str`](https://docs.raku.org/type/Str) type. But then it can be one of:

  * *sq-string* - single-quoted string

  * *dq-string* - double-quoted string

  * *file-path*

  * *keyword*

With this key one can be even more explicit as to what values are acceptable:

    my $cfg = Config::BINDish.new: ...,
                options => (
                    location => { :in<srv-ph>, type => { $_ ~~ Stringy && $*CFG-VALUE.payload.contains('Rack') },
                    location => { :in<srv-vm>, type => { $_ ~~ Stringy && $*CFG-VALUE.payload.contains('Cluster') },
                    location => { :in<pdf-collection image-collection>, :type(Str), :type-name<file-path> }
                );

With this declaration the following config is incorrect:

    pdf-collection "user uploads" {
        location "/mnt/cloud-data/uploads/pdf"
    }

Yet, same as with the `type` key, `type-name` is used as smartmatch operator RHS. Therefore if we replace it with: `:type-name(/^ [ "file-path" | .. "-string" ] $/)` or `:type-name(any <file-path sq-string dq-string>)` – then the above snipped will become valid.

#### `value-sym`

This key defines an exact list of allowed grammar rules/tokens of `value:sym<...>` candidates to be tried when a value is parsed. The list must contain the words used between `< >` symbols of `:sym` adverb. I.e. for the `multiplier` option from a previous example we can explicitly make the grammar even don't attempt matching on anything but the numeric values:

    multiplier => { :value-sym<num rat int>, ... }

With this pre-declaration the grammar will attempt only tokens `value:sym<num>`, `value:sym<rat>`, `value:sym<int>`. In this case the following example will throw with `Config::BINDish::X::Parse::General` instead of `Config::BINDish::X::Parse::ValueType`:

    multiplier "3.1415926";

When the grammar iterates over `value-sym` items it sets `$*CFG-SPECIFIC-VALUE-SYM` dynamic to the currently attempted item. This allows the candidate token to know that it is being expected to succeed and some additional measures could be taken to fulfill the expectations.

For example, if we expect an option to be a file system path then the following example is likely not to parse correctly because the value can be considered both a keyword or a single path element:

    pathy etc;

For this reason `value:sym<file-path>` candidate does not attempt parsing something as a path unless it finds a slash separator. I.e. for the above example to work it must look like:

    pathy /etc;

or

    pathy etc/;

But if we pre-declare the option like:

    pathy => { :value-sym<file-path>, ... }

Then `value:sym<file-path>` would know that `etc` would not be tried as a keyword and it can safely consider it a file/directory name.

#### `named`

Block-only key. If *True* then block must have a name. If *False* then block must not be named. Omitting this key allows the name to be optional.

#### `classified`

Block-only. Similar to `named` but for block class. Only makes sense if `named` is true or optional and block name is specified. Otherwise this key is ignored.

#### `value-only`

Block-only. If this key is set to *True* then the block can not contain options, only values are allowed. I.e. with a declaration like:

    foo => { :value-only }

The following config would be an error:

    foo { option 42 }

But the following example will work:

    foo { 13; 42; 3.1415926 }

Note that within a value-only block keywords are treated as keyword values, not as boolean options:

    foo { value1; value2 } # Two string values with type name 'keyword'
    bar { value1; value2 } # Two True options because bar is not pre-declared

Here is an example of how this peculiarity can be used:

    acl office { 192.168.42.0/24; 192.168.13.0/24 }
    acl data-center { 10.42.0.0/16 }
    acl customers { 172.10.0.0/16 }
    acl any { 0.0.0.0/0 }
    network "internal" {
        access-rules {
            allow { office; data-center } # 'allow' is a value-only block
            disable { any }; # value-only block too
        }
    }
    network "public" {
        access-rules { allow { any } }
    }

### Reservations

#### Names

All keywords and IDs starting with a dot are reserved for internal use. Any use of dot-started names/IDs like *.foo* is discouraged.

#### Option And Block Keywords

The grammar reserves the following keywords for internal use:

  * `include`

  * `use`

#### Blocks

Two blocks are used internally by the grammar: `.TOP` and `.ANYWHERE`. The first one is a kind of global context, where all top-level blocks and options are installed. The name can also be use in a pre-declaration to specify that a statement can be used at the top-level:

    options => ( foo => { :in<.TOP> } )

`.ANYWHERE` is used in pre-declaration context to keep track of pre-declared statements which do not have `in` key and therefore can be used literally anywhere in a config file.

Note that no keyword can start with a dot. Therefore there is no way to accidentally declare `.TOP { }` or `.ANYWHERE { }`, even though technically and formally the config file looks like:

    .TOP {
        include "your-config.cfg"
    }

#### IDs

As it was stated in the [Names](#Names) section any ID string starting with a dot is reserved. Use method `autogen-id` if you need a unique one.

EXTENSIONS
==========



This section provides tips for writing own grammar extensions. See [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Actions.md) to find more about action extensions.

Context
-------

The grammar maintains current parsing context as a way to validate various aspects of config file syntax. In this task it relies upon:

  * `Config::BINDish::Grammar::Context` class

  * `$*CFG-CTX` and `$*CFG-PARENT-CTX` variables containing instances of the `Context` class

  * roles `Config::BINDish::Grammar::StatementProps`, `Config::BINDish::Grammar::ContainerProps` and classes consuming them: `Config::BINDish::Grammar::OptionProps` and `Config::BINDish::Grammar::BlockProps`

  * Raku call stack

Most of the context implementation mechanics are not standardized and subject for change. Yet, a few elements are rather unlikely to change. Among those are:

  * A context has a type, stored in the same-named attribute of the `Context` class. The currently used types are: *"TOP"*, *"BLOCK"*, and *"OPTION"*

  * Except for the *"TOP"* context, all other contexts keep track of their enclosing context via `$.parent` attribute of the `Context` class

  * A context's primary purpose is to provide properties of the currently begin parsed syntax element. Those properties are provided by `props` attribute of the `Context` class and expected to consume `StatementProps` role

If you plan to implement a grammar extension with a rule or token providing own context then it'd make sense to follow the steps taken by `statement:sym<option>` or `statement:sym<block>` rules.

Extending The Grammar
---------------------

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md) contains general information about writing extensions. Here we provide only grammar-specific details.

Only the rules and tokens documented in corresponding section above are guaranteed to be supported and not be changed or removed without deprecation.

The most common way to extend the grammar would be to add a new kind of statement or value type. This must be as easy as adding new rules or tokens akin to the following example:

    role MyExtension is BINDish-grammar {
        ...
        multi rule statement:sym<your-statement> {
            # Your statement syntax rules
        }
        multi token value:sym<your-type> {
            # Your value syntax rules
        }
        ...
    }

SEE ALSO
========

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/Strictness.md), [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/ContainerProps.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/OptionProps.md), [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.5/docs/md/Config/BINDish/Grammar/BlockProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

