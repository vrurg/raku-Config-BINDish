NAME
====

`Config::BINDish::Grammar` - the central class of everything in `Config::BINDish`

DESCRIPTION
===========

This class is responsible for the actual parsing of the configuration. It is not recommended for direct use. [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md) `read` method must be used instead.

The class inherits from the standard [`Grammar`](https://docs.raku.org/type/Grammar) class.

ATTRIBUTES
==========

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.flat`

If set this attribute expects blocks to be flattened down. I.e. whenever a block has a duplicate declaration in the config the later declaration must be applied on top of the first one. This doesn't change grammar's behavior but rather serves as a note for the actions class to take care of the situation. One way or another, if this attribute is *True* then the user expects a single block `foo "bar"` representation to exists after the following sample is parsed:

    foo "bar" { fubar 1; }
    baz { }
    foo "bar" { fubar 2; fubaz 3.14; }

How the options are dealt with is the sole prerogative of the actions implementation. [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Actions.md) re-delegates handling of flattening to the underlying [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST.md) class. It, in turn, will overwrite earlier option declarations with latter ones. So, when one queries for `fubar` the value returned will be *2*.

See [$*CFG-FLAT-BLOCKS](#$*CFG-FLAT-BLOCKS).

### [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Strictness.md) `$.strict = False`

Defines what strictness modes are activated. See [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Strictness.md).

### `%.blocks`

User-defined blocks in hash form. Passed to `declare-blocks` method at object construction time.

See [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/BlockProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

### `%.options`

User-defined options in hash form. Passed to `declare-options` method at object construction time.

See [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/OptionProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

DYNAMIC VARIABLES
=================

The grammar declares and uses a set of dynamic variables to pass certain information between its rules, tokens, methods, and the actions object.

### `$*CFG-GRAMMAR`

The primary grammar object. Due to the way the [`Grammar`](https://docs.raku.org/type/Grammar) is implemented `self` does not always point to the same object created by the initial `parse` method. These instances are not full clones of the original grammar and do not inherit all attribute values from it. For this reason when access to the user-set attributes is needed the original grammar is better be easily available.

### `$*CFG-FLAT-BLOCKS`

Set to `$.flat` attribute value.

### `$*CFG-INNER-PARENT`

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/Parent.md).

### `$*CFG-TOP`

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::TOP`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/AST/TOP.md).

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-VALUE`

Must be provided directly or indirectly by any rule or token invoking the `<value>` token. This variable will be set to a [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) instance created by `set-value` method.

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-KEYWORD`

Set by `<keyword>` token. The value stored will be of type [`Str`](https://docs.raku.org/type/Str) and have type name *"keyword"*.

### `$*CFG-BLOCK-TYPE`, `$*CFG-BLOCK-NAME`, `$*CFG-BLOCK-CLASS`

All three are of [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) type. When the following example is parsed:

    foo "bar" baz { }

The variables will be set to:

  * type: "foo" of [`Str`](https://docs.raku.org/type/Str), type-name *"keyword"*

  * name: "bar" of [`Str`](https://docs.raku.org/type/Str), type name *"dq-string"*

  * class: "baz" of [`Str`](https://docs.raku.org/type/Str), type name *"keyword"*

Note that the name could be of any value, supported by the grammar. If an extension adds a new value type then the type can also be used as a type name. Say, with [`Config::BINDish::INET`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/INET.md) loaded one can have the following valid declaration:

    IP 192.168.1.42 { }

For which the name will be set to type `IP::Addr`, type-name *"IPv4"*.

### `$*CFG-BLOCK-ERR-POS`

This variable is set to a [`Match`](https://docs.raku.org/type/Match) object pointing at the location where current block declaration starts. Can be used for error reporting.

METHODS
=======

### `set-value(Mu \type, *%value)`

This methods creates a new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) object and assigns it to `$*CFG-VALUE`. Takes value's type object as its single positional parameter. Type name and payload are passed as the only named argument of the method call. Here is how a single-quoted string is handled by the grammar:

    token sq-string {
        \' ~ \' $<string>=<.qstring("'")>
        {
            self.set-value: Str, :sq-string($<string>)
        }
    }

In this example the new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Value.md) object will be created with payload set from `$<string>`, type name set to *"sq-string"*, and type set to [`Str`](https://docs.raku.org/type/Str).

### `submethod setup-BINDish`

When the grammar is instantiated it iterates over all of its parents and roles and invokes each unique `setup-BINDish` submethod it finds. While it may seem to look as a duplicate of `TWEAK`, the purpose of using this approach is to eliminate the differences in handling of submethods by Raku versions 6.c/d and 6.e.

See also [Pre-declaration](#Pre-declaration) section in [EXTENSIONS](#EXTENSIONS).

### `multi declare-blocks(%blocks)`

### `multi declare-blocks(*%blocks)`

Pre-declare blocks properties. See [Pre-declaration](#Pre-declaration) section below for details.

### `multi declare-options(%options)`

### `multi declare-options(*%options)`

Pre-declare options properties. See [Pre-declaration](#Pre-declaration) section below for details.

### `cfg-ctx()`

Returns current active context object. See [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Context.md).

The method will automatically fall back to `$*CFG-GRAMMAR` if the instance it is invoked upon is not the primary grammar object.

### `push-ctx(*%ctx-profile)`

Creates and pushes to context stack a new [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Context.md) object. Returns the new context.

Falls back to `$*CFG-GRAMMAR` if necessary.

### `pop-ctx()`

Pops and returns the current context object from the context stack. Will die if attempt to pop the *"TOP"* context is made.

### `block-ok(Str:D $block-type --` Bool)>

Returns *True* if block `$block-type` can be used in the current context. For example, if a block type *name-servers* is [pre-declared](#Pre-declaration) to be only allowed within a *network* block then `block-ok` will return *False* if *name-servers* is used in a *host* block or at the configuration top-level.

### `option-ok(Str:D $keyword --` Bool)>

Similarly to `block-ok` method, returns *True* only if option `$keyword` is allowed in the current block context.

### `enter-option()`

Set the current context as *"OPTION"*. Uses [`$*CFG-KEYWORD`](#$*CFG-KEYWORD) to determine option name and fetch its pre-declarion properties if there are any.

Knowing if current context is option or not is rather useful to find out of a syntax element should have special treatment. For example, if a keyword is seen in option context it is treated as a value, not as a boolean option. For example:

    access-allowed private-acl;

Here `private-acl` is parsed as a string *'private-acl'* with type name set to `keyword`. Our code could then consult with the type name to find out the value is by chance a reference to a block or another option.

### `leave-option()`

Must be invoked when leaving option context.

### `leave-block()`

Must be invoked when leaving block context.

### `validate-block()`

Does complex validation of a block based on its type, name, and, possibly, class. Uses pre-set variables [`$*CFG-BLOCK-TYPE`](#$*CFG-BLOCK-TYPE), [`$*CFG-BLOCK-NAME`](#$*CFG-BLOCK-NAME), [`$*CFG-BLOCK-CLASS`](#$*CFG-BLOCK-CLASS). If block passes the validation then a new block context is pushed onto the context stack.

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ExtraPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/ExtraPart.md), [`Config::BINDish::X::Parse::MissingPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/MissingPart.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-option()`

Does complex validation of an option based on its name. Uses pre-set variables [`$*CFG-KEYWORD`](#$*CFG-KEYWORD) and [`$*CFG-VALUE`](#$*CFG-VALUE).

Contrary to `validate-block` method results in leaving option context.

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/ValueType.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-value()`

Makes sure a value can be used in the current context. Uses variable [`$*CFG-VALUE`](#$*CFG-VALUE).

Can throw [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/ValueType.md).

### `multi method panic(Str:D $msg)`

Throws [`Config::BINDish::X::Parse::General`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/X/Parse/General.md) with message `$msg`.

### `multi method panic(Config::BINDish::X::Parse:U \exception, Str $msg?, *%profile)`

Creates an object of type `exception` using `%profile` as named arguments for constructor and throws it. If $msg is specified then it is added to the profile as named argument `:$msg`.

Both `panic` methods also pass the grammar object they're invoked upon as `cursor` named argument to provide the exception instance with error location and other useful information.

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

Does nothing, used as anchor for [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Actions.md).

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

Double- and single-quoted strings. The standard grammar and actions do not care about the exact nature of a string. But extensions could adjust their behavior based on the string type. For example, [`Config::BINDish::Expandable`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Expandable.md) implements macro expansion for double-quoted strings only.

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

EXTENSIONS
==========



This section provides tips for writing own grammar extensions. See [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Actions.md) to find read about action extensions.

Pre-declaration
---------------

*Note:* This section also applies to attributes [`%.blocks`](#%.blocks) and [`%.options`](#%.options) mentioned above.

An extension can pre-declare own blocks and options. It must do so by declaring a submethod named `setup-BINDish` and calling methods `declare-blocks` and `declare-options`. Both methods take [`Hash`](https://docs.raku.org/type/Hash) objects or named arguments. In other words, the following two calls are identical:

    self.declare-options: opt1 => {:top-only}, opt2 => %(:in<foo>, :type<Num>);
    self.declare-options: %( opt1 => {:top-only}, opt2 => %(:in<foo>, :type<Num>) );

Each hash or named argument key define the keyword of corresponding construct. Apparently, in the above example options `opt1` and `opt2` are declared.

Keys of each option or block declaration define corresponding properties of each entitity. They're also named after attributes of the following typeobjects:

  * [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/ContainerProps.md) - common to both options and blocks

  * [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/OptionProps.md) - specific to options

  * [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/BlockProps.md) - specific to blocks

### Keys common to both options and blocks

Statement level keys:

  * `top-only` - a statement can not be part of any block declaration

  * `in` - set of blocks inside which a statement is allowed

Container level keys:

  * `type-name` - allowed type names

  * `type` – allowed types

The above two keys are used as RHS for smartmatching. It allows explicit declarations of the following kind:

    my $cfg = Config::BINDish.new:
            :strict{:options},
            options => %(
                multi-type => { :in<general>, type => Int | Rat },
                stringy => { :in<general>, type-name => /\- string$/ },
            );

With this we can have options like:

    multi-type 2M;
    multi-type 1.5G;
    stringy "double quoted"; # Because of type name 'dq-string'
    stringy 'single quoted"; # ... and 'sq-string'

But not:

    multi-type 1.5e2; # The value is Num
    stringy bareword; # The value is a string, but its type name is 'keyword'

### Option-only keys

Options currently do not have any declaration keys unique to them.

### Block-only keys

  * `named` - specifies if block must have a name. If omitted then the name part of block declaration is optional. If *True*, name is required; if *False* then block can't have a name.

  * `classified` - similar to the `named` above, but controls block class. Ignored altogether if `named` is *False*.

  * `value-only` - if *True* then the block can only have a list of values in its body. Set to *False* by default. Only value-only blocks can contain keywords as values; all other blocks treat keywords as boolean options.

Context
-------

Grammar object has a way of handling configuration file context by maintaining own context stack of [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Context.md) objects. See methods `push-ctx`, `pop-ctx`, and `cur-ctx`.

The only property of context which is guaranteed to be defined is its type. It's a string with context name. Currently only three of them can be seen: *"TOP"*, *"BLOCK"*, and *"OPTION"*.

Extending The Grammar
---------------------

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md) contains general information about writing extensions. Here we provide only grammar-specific details.

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

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/Strictness.md), [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/ContainerProps.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/OptionProps.md), [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.2/docs/md/Config/BINDish/Grammar/BlockProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

