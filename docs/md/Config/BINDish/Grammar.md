NAME
====

`Config::BINDish::Grammar` - the central class of everything in `Config::BINDish`

DESCRIPTION
===========

This class is responsible for the actual parsing of the configuration. It is not recommended for direct use. [`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md) `read` method must be used instead.

The class inherits from the standard [`Grammar`](https://docs.raku.org/type/Grammar) class.

ATTRIBUTES
==========

### [`Bool:D`](https://docs.raku.org/type/Bool) `$.flat`

If set this attribute expects blocks to be flattened down. I.e. whenever a block has a duplicate declaration in the config the later declaration must be applied on top of the first one. This doesn't change grammar's behavior but rather serves as a note for the actions class to take care of the situation. One way or another, if this attribute is *True* then the user expects a single block `foo "bar"` representation to exists after the following sample is parsed:

    foo "bar" { fubar 1; }
    baz { }
    foo "bar" { fubar 2; fubaz 3.14; }

How the options are dealt with is the sole prerogative of the actions implementation. [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md) re-delegates handling of flattening to the underlying [`Config::BINDish::AST`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST.md) class. It, in turn, will overwrite earlier option declarations with latter ones. So, when one queries for `fubar` the value returned will be *2*.

See [$*CFG-FLAT-BLOCKS](#$*CFG-FLAT-BLOCKS).

### [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Strictness.md) `$.strict = False`

Defines what strictness modes are activated. See [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Strictness.md).

### `%.blocks`

User-defined blocks in hash form. Passed to `declare-blocks` method at object construction time.

See [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/BlockProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

### `%.options`

User-defined options in hash form. Passed to `declare-options` method at object construction time.

See [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/OptionProps.md) and [Pre-declaration](#Pre-declaration) section for more information.

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

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::Parent`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/Parent.md).

### `$*CFG-TOP`

Provided for actions convenience. Intended to hold an instance of [`Config::BINDish::AST::TOP`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/AST/TOP.md).

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-VALUE`

Must be provided directly or indirectly by any rule or token invoking the `<value>` token. This variable will be set to a [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) instance created by `set-value` method.

### [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) `$*CFG-KEYWORD`

Set by `<keyword>` token. The value stored will be of type [`Str`](https://docs.raku.org/type/Str) and have type name *"keyword"*.

### `$*CFG-BLOCK-TYPE`, `$*CFG-BLOCK-NAME`, `$*CFG-BLOCK-CLASS`

All three are of [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) type. When the following example is parsed:

    foo "bar" baz { }

The variables will be set to:

  * type: "foo" of [`Str`](https://docs.raku.org/type/Str), type-name *"keyword"*

  * name: "bar" of [`Str`](https://docs.raku.org/type/Str), type name *"dq-string"*

  * class: "baz" of [`Str`](https://docs.raku.org/type/Str), type name *"keyword"*

Note that the name could be of any value, supported by the grammar. If an extension adds a new value type then the type can also be used as a type name. Say, with [`Config::BINDish::INET`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/INET.md) loaded one can have the following valid declaration:

    IP 192.168.1.42 { }

For which the name will be set to type `IP::Addr`, type-name *"IPv4"*.

### `$*CFG-BLOCK-ERR-POS`

This variable is set to a [`Match`](https://docs.raku.org/type/Match) object pointing at the location where current block declaration starts. Can be used for error reporting.

### `$*CFG-SPECIFIC-VALUE-SYM`

Set by the grammar whenever a specific value type is expected. See more details in [value-sym](#value-sym) section below.

### `$*CFG-BACKTRACK-OPTION`, `$*CFG-BACKTRACK-BLOCK`

These variables are set by corresponding `backtrack-*` method to indicate the context in which `leave-*` methods are called. In other words, if `!$*CFG-BACKTRACK-OPTION` is *True* then an option has been successfully parsed.

METHODS
=======

### `set-value(Mu \type, *%value)`

This methods creates a new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) object and assigns it to `$*CFG-VALUE`. Takes value's type object as its single positional parameter. Type name and payload are passed as the only named argument of the method call. Here is how a single-quoted string is handled by the grammar:

    token sq-string {
        \' ~ \' $<string>=<.qstring("'")>
        {
            self.set-value: Str, :sq-string($<string>)
        }
    }

In this example the new [`Config::BINDish::Grammar::Value`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Value.md) object will be created with payload set from `$<string>`, type name set to *"sq-string"*, and type set to [`Str`](https://docs.raku.org/type/Str).

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

See also [Pre-declaration](#Pre-declaration) section in [EXTENSIONS](#EXTENSIONS).

### `multi declare-blocks(%blocks)`

### `multi declare-blocks(*%blocks)`

Pre-declare blocks properties. See [Pre-declaration](#Pre-declaration) section below for details.

### `multi declare-options(%options)`

### `multi declare-options(*%options)`

Pre-declare options properties. See [Pre-declaration](#Pre-declaration) section below for details.

### `cfg-ctx()`

Returns current active context object. See [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Context.md).

The method will automatically fall back to `$*CFG-GRAMMAR` if the instance it is invoked upon is not the primary grammar object.

### `enter-ctx(*%ctx-profile)`

Creates and pushes to context stack a new [`Config::BINDish::Grammar::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Context.md) object. Returns the new context.

Falls back to `$*CFG-GRAMMAR` if necessary.

### `block-ok(Str:D $block-type --` Bool)>

Returns *True* if block `$block-type` can be used in the current context. For example, if a block type *name-servers* is [pre-declared](#Pre-declaration) to be only allowed within a *network* block then `block-ok` will return *False* if *name-servers* is used in a *host* block or at the configuration top-level.

### `option-ok(Str:D $keyword --` Bool)>

Similarly to `block-ok` method, returns *True* only if option `$keyword` is allowed in the current block context.

### `backtrack-option()`

A callback method invoked by `statement:sym<option>` rule if it fails to parse a statement as an option. This does not necessarily mean that there was a syntax error in the configuration source as the rule start parsing anything starting with a keyword as an option, including valid block declarations.

Invokes `leave-option` method.

### `backtrack-block()`

Similar to `backtrack-option` method above but for block declarations.

Invokes `leave-block` method.

### `leave-option()`

Must be invoked when leaving option context.

### `leave-block()`

Must be invoked when leaving block context.

### `validate-block()`

Does complex validation of a block based on its type, name, and, possibly, class. Uses pre-set variables [`$*CFG-BLOCK-TYPE`](#$*CFG-BLOCK-TYPE), [`$*CFG-BLOCK-NAME`](#$*CFG-BLOCK-NAME), [`$*CFG-BLOCK-CLASS`](#$*CFG-BLOCK-CLASS). If block passes the validation then a new block context is pushed onto the context stack.

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ExtraPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/ExtraPart.md), [`Config::BINDish::X::Parse::MissingPart`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/MissingPart.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-option()`

Does complex validation of an option based on its name. Uses pre-set variables [`$*CFG-KEYWORD`](#$*CFG-KEYWORD) and [`$*CFG-VALUE`](#$*CFG-VALUE).

Contrary to `validate-block` method results in leaving option context.

Can throw one of [`Config::BINDish::X::Parse::Context`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/Context.md), [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/ValueType.md), or [`Config::BINDish::X::Parse::Unknown`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/Unknown.md).

### `validate-value()`

Makes sure a value can be used in the current context. Uses variable [`$*CFG-VALUE`](#$*CFG-VALUE).

Can throw [`Config::BINDish::X::Parse::ValueType`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/ValueType.md).

### `multi method panic(Str:D $msg)`

Throws [`Config::BINDish::X::Parse::General`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/X/Parse/General.md) with message `$msg`.

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

Does nothing, used as anchor for [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md).

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

Double- and single-quoted strings. The standard grammar and actions do not care about the exact nature of a string. But extensions could adjust their behavior based on the string type. For example, [`Config::BINDish::Expandable`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Expandable.md) implements macro expansion for double-quoted strings only.

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



This section provides tips for writing own grammar extensions. See [`Config::BINDish::Actions`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Actions.md) to find read about action extensions.

Pre-declaration
---------------

*Note:* This section also applies to attributes [`%.blocks`](#%.blocks) and [`%.options`](#%.options) mentioned above.

An extension can pre-declare own blocks and options. It must do so by declaring a submethod named `setup-BINDish` and calling methods `declare-blocks` and `declare-options`. Both methods take [`Hash`](https://docs.raku.org/type/Hash) objects or named arguments. In other words, the following two calls are identical:

    self.declare-options: opt1 => {:top-only}, opt2 => %(:in<foo>, :type<Num>);
    self.declare-options: %( opt1 => {:top-only}, opt2 => %(:in<foo>, :type<Num>) );

Each hash or named argument key define the keyword of corresponding construct. Apparently, in the above example options `opt1` and `opt2` are declared.

Keys of each option or block declaration define corresponding properties of each entitity. They're also named after attributes of the following typeobjects:

  * [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/ContainerProps.md) - common to both options and blocks

  * [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/OptionProps.md) - specific to options

  * [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/BlockProps.md) - specific to blocks

### Keys common to both options and blocks

Statement level keys:

  * `top-only` - a statement can not be part of any block declaration

  * `in` - set of blocks inside which a statement is allowed

Container level keys:

  * `type-name` - allowed type names

  * `type` – allowed types

  * `value-sym` - list of expected value types; see below for more details

The first two keys are used as RHS for smartmatching. It allows explicit declarations of the following kind:

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

#### `value-sym`

This key is responsible for a little bit tricky but very powerful feature. Value parsing is implemented with `value` token which is a `proto`. Apparently, variants of the token are declared using `:sym<...>` notation. `value-sym` defines one or more types allowed for this container as they're specified between the angle brackets in `:sym<...>` postfix in a `value` token candidate. For example, if we want an option value to only be parsed as a numeric, we can declare it like:

    options => %(
        opt-numish => { value-sym => <int num rat> }
    )

And the parser will only try parsing `opt-numish` value with `value:sym<int>`, `value:sym<num>`, or `value:sym<rat>` candidates, ignoring all other. Moreover, it will set `$*CFG-SPECIFIC-VALUE-SYM` dynamic to the currently considered type. This would allow the candidate to know that it is being expected to succeed and some additional measures could be taken to fulfill the expectation. For example, if we expect an option to be a file system path then the following example is likely not to parse correctly because the value can be considered both a keyword or a single path element:

    pathy etc;

For this reason `file-path` candidate does not attempt parsing something as a path unless it finds a slash separator. I.e. for the above to work one must write it as `/etc` or `etc/`.

But if we declare the option with `value-sym` set to `file-path` then the ambiguity is explicitly resolved and `value:sym<file-path>` will successfully parse `etc` as a single-element path.

### Option-only keys

Options currently do not have any declaration keys unique to them.

### Block-only keys

  * `named` - specifies if block must have a name. If omitted then the name part of block declaration is optional. If *True*, name is required; if *False* then block can't have a name.

  * `classified` - similar to the `named` above, but controls block class. Ignored altogether if `named` is *False*.

  * `value-only` - if *True* then the block can only have a list of values in its body. Set to *False* by default. Only value-only blocks can contain keywords as values; all other blocks treat keywords as boolean options.

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

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md) contains general information about writing extensions. Here we provide only grammar-specific details.

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

[`Config::BINDish`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish.md), [`Config::BINDish::Grammar::Strictness`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/Strictness.md), [`Config::BINDish::Grammar::StatementProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/StatementProps.md), [`Config::BINDish::Grammar::ContainerProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/ContainerProps.md), [`Config::BINDish::Grammar::OptionProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/OptionProps.md), [`Config::BINDish::Grammar::BlockProps`](https://github.com/vrurg/raku-Config-BINDish/blob/v0.0.3/docs/md/Config/BINDish/Grammar/BlockProps.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

