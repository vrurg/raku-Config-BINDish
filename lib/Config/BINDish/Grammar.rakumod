use v6.d;

#no precompilation;
#use Grammar::Tracer;
use nqp;
unit grammar Config::BINDish::Grammar;
use Config::BINDish::X;
use AttrX::Mooish;

our @coercers;
BEGIN {
    # Get all suspected methods-coercers. A method is considered coercer if lexical named after the method name is
    # a typeobject.
    @coercers = (|Match.^methods(:all), |Str.^methods(:all))
                    .map(*.name)
                    .unique
                    .grep({ LEXICAL::{$_}:exists && !LEXICAL::{$_}.defined });
}

role Context          {...}
class Context::Block  {...}
class Context::Option {...}

role TypeStringify {
    method type-name {...}
    method type {...}

    method type-as-str(--> Str:D) {
        my @parts;
        with $.type-name {
            @parts.push: .^does(Stringy) ?? '<' ~ $_ ~ '>' !! .gist
        }
        @parts.push: $.type.gist unless $.type<> =:= Mu;
        @parts.join(" of ")
    }
}

my subset Payload of Any where Match | Str;
class Value does TypeStringify {
    has Str:D $.type-name is required;
    has Mu $.type is required;
    has Payload:D $.payload is required handles @coercers;

    has Mu $.coerced is mooish(:lazy);

    multi method gist(::?CLASS:D:) {
        my $val = Str($!payload);
        my $quote = $!type-name eq 'dq-string' ?? '"' !! "'";
        $!type ~~ Stringy ?? $quote ~ $val ~ $quote !! $val
    }

    method build-coerced(::?CLASS:D: --> Mu) {
        -> ::T { T($!payload) }.($!type)
    }
}

my class InSet {
    has %!blocks is Map is built(:bind) handles(<keys Bool>);
    method new(Mu $from) { self.bless: blocks => $from.list.map({ ($_ ~~ Pair) ?? $_ !! ($_ => True) }).Map }
    method ACCEPTS(Context::Block:D $blk) { %!blocks{$blk.id}:exists && $blk.class ~~ %!blocks{$blk.id} }
}

role StatementProps {
    # If non-empty then this statement can only be contained by blocks listed here.
    has InSet:D() $.in = ();
    # If statement can only be declared at the top level
    # DEPRECATED To be removed. Replaced with uniform :in<.TOP> format
    has Bool:D $.top-only = False;
    # If a statement declaration has been auto-created on demand.
    has Bool:D $.autovivified = False;

    multi method COERCE(%profile) {
        self.new: |%profile
    }

    multi method ACCEPTS(Context:D $ctx) {
        my $cur-block = $ctx.cur-block-ctx;
        return $cur-block.is-TOP if $!top-only;
        $!in ?? ( $cur-block ~~ $!in) !! True
    }

    method Bool { False }
}

role ContainerProps does TypeStringify {
    # A list of value token sym names allowed for this container. For example, an option can be limited to be a
    # value:sym<int> only.
    has List(Str) $.value-sym;
    # These attributes are used as RHS of a smartmatch.
    # NOTE: These are kept separate from StatementProps because extensions may add non-container type statements.
    has $.type-name;
    has Mu $.type;
    # Default value of a container
    has Mu $.default is default(Nil);

    # Don't forget keeping can-type and ACCEPTS in sync in their semantics until inlining would be able to
    # sufficiently optimize ACCEPTS calling can-type
    method can-type(Str $type-name, Mu $type) {
        (!$!type-name.defined || $type-name ~~ $!type-name)
        && ($!type =:= Mu || $type ~~ $!type)
    }

    multi method ACCEPTS(Value:D $val) {
        (!$!type-name.defined || $val.type-name ~~ $!type-name)
        && ($!type =:= Mu || $val.type ~~ $!type)
    }
}

role DeclarationProps {
    # Each declaration should have an ID unique among other declarations of its kind
    has Any:D $.id is required;
    # Keyword used to declare an entity.
    has Str:D $.keyword is required;
}

class OptionProps
    does StatementProps
    does ContainerProps
    does DeclarationProps {}

class BlockProps
    does StatementProps
    does ContainerProps
    does DeclarationProps
{
    # Block must be named or is optional if not set
    has Bool $.named;
    # Block must have a class or is optional if not set
    has Bool $.classified;
    # Block can only contain values, no options or blocks allowed
    has Bool:D $.value-only = False;
    # Block may not contain values. Conflicts with the above.
    has Bool:D $.no-values = False;

    submethod TWEAK(|) {
        my $value-prop = $!value-only ?? 'value-only' !! ($!value-sym ?? 'value-sym' !! Nil);
        if $value-prop && $!no-values {
            Config::BINDish::X::ConflictingProps.new(
                :prop1($value-prop), :prop2<no-values>,
                :reason("both are set for block '" ~ self.keyword ~ "'" )).throw
        }
    }

    method values {
        return .List with $.default;
        ()
    }
}

role Context {
    # ID of the current statement properties. $!type defines the key where to search for the ID on %!props.
    has $.id;
    # Statement type (keyword)
    has Value $.keyword;
    has ::?ROLE $.parent;
    has StatementProps $.props is mooish(:lazy);
    has $.relations is mooish(:lazy);

    method build-props {
        $*CFG-GRAMMAR.props{self.type}{$!id}
    }

    method build-relations {
        return Nil unless self.props ~~ BlockProps;
        $*CFG-GRAMMAR.prop-relations{$!id}
    }

    method parent(::?CLASS:D: Int:D $count = 0 --> ::?CLASS:D) {
        return $!parent unless $count;
        $!parent.parent($count - 1)
    }

    method cur-block-ctx(::?CLASS:D: --> Context::Block) {
        $!parent ?? $!parent.cur-block-ctx !! Nil
    }

    method description(::?CLASS:D:) {
        die "Internal: looks like " ~ $_ ~ " context hasn't been given a description!"
    }

    multi method ACCEPTS(StatementProps:D $props) {
        !$props.in || (self.cur-block-ctx andthen $_ ~~ $props.in)
    }

    method type {...}
}

class Context::Block does Context {
    has Value $.name;
    has Value $.class;

    method description(::?CLASS:D:) {
        $.id eq '.TOP'
            ?? 'global context'
            !! ("block '"
                ~ $.keyword.coerced
                ~ ($.name.defined
                    ?? ' ' ~ $.name.gist
                    !! "")
                ~ ($.class.defined ?? ' ' ~ $.class.gist !! "")
                ~ "'")
    }

    method is-TOP { $.id eq '.TOP' }

    method type { "block" }

    method cur-block-ctx(::?CLASS:D:) { self }
}

class Context::Option does Context {
    method description(::?CLASS:D:) {
        "option '" ~ $.keyword.coerced ~ "'"
    }

    method type { "option" }
}

class Strictness {
    has Bool:D $.syntax = False;
    has Bool:D $.options = False;
    has Bool:D $.blocks = False;
    has Bool:D $.warnings = True;
    multi method COERCE(Hash:D $p) { self.new: |$p }
    multi method COERCE(Pair:D $p) { self.new: |$p }
    multi method COERCE(Positional:D $l where { ? all .map(* ~~ Pair) }) { self.new: |%$l }
    multi method COERCE(Bool:D $default) { self.new: |%(<syntax options blocks warnings> X=> $default) }
}

# Where we read from
has $!file is built;
has Int:D $.line-delta = 0;
has Bool:D $.flat = False;
has Strictness:D() $.strict = False;
# Keys expected in %.props. The order matters for registry building.
has @.prop-keys is mooish(:lazy);
# Pre-declared statement properties. First level keys are statements types: "block" or "option". Second level are IDs
has Hash[StatementProps:D] %.props is mooish(:lazy);
# Registered keywords as SetHash, per statement type (first level key)
has SetHash %.keywords is mooish(:lazy);
# This is a registry where for each block ID (first level key) a hash of bound keywords is stored as the third level
# key. Values are keyword's DeclarationProps. Second level keys are values from @.prop-keys.
has %.prop-relations is mooish(:lazy, :clearer);
# User-defined blocks and options, set-only.
has Pair:D @.blocks;
has Pair:D @.options;

has SetHash:D %!reserved-keywords is mooish(:lazy);

proto method reserve-keywords(|) {*}
multi method reserve-keywords(Str:D $what, @keywords) {
    %!reserved-keywords{$what}.set: @keywords
}
multi method reserve-keywords(*%p) {
    for %p.kv -> $what, $keywords {
        samewith $what, $keywords.list;
    }
}

proto method is-reserved(|) {*}
multi method is-reserved(Str:D $what, Str:D $keyword --> Bool:D) {
    ? %!reserved-keywords{$what}{$keyword}
}
multi method is-reserved(*%p where *.elems == 1) {
    samewith |%p.kv
}

proto method set-value(|) {*}
multi method set-value(Mu $type is raw, *%tinfo where *.elems == 1 --> Value:D) {
    my ($type-name, $payload) = %tinfo.kv;
    $*CFG-VALUE = Value.new: :$type, :$payload, :$type-name
}
multi method set-value(Value:D $val --> Value:D) {
    $*CFG-VALUE = $val
}

method set-line-relative(Int:D $l, Int:D :$to = self.line(:absolute)) {
    return $*CFG-GRAMMAR.set-line-relative($l, :$to) unless self === $*CFG-GRAMMAR;
    $!line-delta = $to - $l + 1;
}

method set-file($file) {
    return $*CFG-GRAMMAR.set-file($file) unless self === $*CFG-GRAMMAR;
    $!file = $file;
}

submethod TWEAK(|) {
    self.reserve-keywords: option => <include use>,
                           block => <include use>;
    # Reserve id ".TOP" but allow user to override it
    self.declare-block: :id<.TOP>, :keyword<.TOP>, :autovivified;
    # Reserve id .ANYWHERE
    self.declare-block: :id<.ANYWHERE>, :keyword<.ANYWHERE>;

    # Walk over grammar's MRO and invoke setup methods.
    # To prevent duplicate iteration over submethods defined in v6.c/v6.d roles
    # record submethod objects we've already invoked.
    my %invoked;
    my @components := $*RAKU.compiler.version >= v2021.10.87.gd.38852628
        ?? self.^mro(:concretizations)
        !! self.^mro(:roles);
    for @components -> \component {
        my &setup-method = nqp::can(component.HOW, 'submethod_table')
            ?? component.^submethod_table<setup-BINDish> // Nil
            !! Nil;
        my $method-which = &setup-method.WHICH;
        if &setup-method && !%invoked{$method-which} {
            %invoked{$method-which} = True;
            self.&setup-method();
        }
    }
}

method build-prop-keys {
    <block option>
}

method build-props {
    @!prop-keys.map({ $_ => Hash[StatementProps:D].new }).Hash
}

method build-keywords {
    @!prop-keys.map: * => SetHash.new
}

method !build-reserved-keywords {
    @!prop-keys.map: * => SetHash.new
}

method build-prop-relations {
    my %relations;
    my $ANYWHERE = %!props<block><.ANYWHERE>;

    for @!prop-keys -> $type {
        # Check all `in`-references and auto-vivify undeclared blocks
        for %!props{$type}.kv -> $id, $prop {
            if $!strict.warnings && $id ~~ Str && $id.index("\t").defined {
                self.warn: "===WARNING!=== Suspcious $type id '$id' contains a TAB in pre-declaration. "
                     ~ "Perhaps you should consider using a list as "
                     ~ $type ~ "s initializer?";
            }
            if $prop.top-only {
                self.warn: "Deprecated option 'top-only' is used for '"
                           ~ $prop.keyword
                           ~ "' with ID '" ~ $prop.id ~ "'. "
                           ~ "Consider replacing it with `:in<.TOP>`.";
                $prop.in<.TOP> = True;
            }
            for $prop.in.keys -> $in-id {
                without %!props<block>{$in-id} {
                    # If `in` referencing an unknown block then we consider it the case where ID is block type
                    self.declare-block: $in-id, $in-id, %( :autovivified ), :!cleanup;
                }
            }
        }
    }

    for @!prop-keys -> $type {
        my $ids = SetHash.new: %!props{$type}.keys;

        my sub add-prop($prop) {
            my $id = $prop.id;
            my $keyword = $prop.keyword;
            if $prop ~~ BlockProps {
                %relations{$id}{$type} := Hash[DeclarationProps:D].new unless %relations{$id}{$type}:exists;
            }

            my sub add-relation($in-prop) {
                Config::BINDish::X::DuplicateKeyword.new(:$keyword, :what($type), :in( $in-prop )).throw
                    if %relations{$in-prop.id}{$type}{$keyword}:exists;
                %relations{$in-prop.id}{$type}{$keyword} = $prop;
            }

            # If a pre-declaration doesn't specify blocks where it is valid then make it a global declaration
            if $prop.in {
                for $prop.in.keys -> $in-id {
                    my $in-prop = %!props<block>{$in-id};
                    add-prop($in-prop) unless %relations{$in-id}:exists;
                    add-relation($in-prop);
                }
            }
            else {
                add-relation($ANYWHERE);
            }
            $ids.unset: $id;
        }

        for %!props{$type}.values -> $prop {
            next unless $prop.id ∈ $ids;
            add-prop($prop);
        }
    }
    %relations
}

method warn(*@msg --> Nil) {
    note "===WARNING!=== " ~ @msg.map(*.gist).join("") if $!strict.warnings;
}

submethod setup-BINDish {
    self.declare-blocks: self.blocks;
    self.declare-options: self.options;
    # Kick-start rebuild of the prop relations attribute
    %!prop-relations.sink;
#    self.declare-blocks:
#        block => { :top-only },
#        subblock => { in => <block> },
#        foo => { :named, :classified },
##        fubar => { :named, in => <block subblock> },
#        ;
#    self.declare-options:
#        val => {},
#        val2 => { type => Str },
#        count => { in => <block>, type-name => 'int', },
#        subval => { in => <subblock> },
#        allow-something => { in => <block> },
#        ;
}

proto method statement-props(Str:D) is raw {*}
multi method statement-props('option') is raw { OptionProps }
multi method statement-props('block') is raw { BlockProps }

proto method context-type(Str:D) is raw {*}
multi method context-type('option') is raw { Context::Option }
multi method context-type('block') is raw { Context::Block }
multi method context-type(Str:D $type) {
    Config::BINDish::X::ContextType.new(:$type).throw
}

my subset Keyword of Any:D where Str | { $_ ~~ Bool && .so };
method declare-statement(Str:D $what,
                         Any:D :$id = self.autogen-id,
                         Keyword :$keyword is copy,
                         :%props,
                         Bool :$cleanup = True
    --> StatementProps:D)
{
    with %!props{$what}{$id} {
        Config::BINDish::X::DuplicateID.new(:props($_), :$keyword, :$what).throw
            unless .autovivified
    }
    self.clear-prop-relations if $cleanup;
    $keyword = $id if $keyword ~~ Bool;
    %!keywords{$what}.set: $keyword;
    %!props{$what}{$id} = self.statement-props($what).new: |%props, :$id, :$keyword
}

proto method declare-block(|) {*}
multi method declare-block(Any:D $id, Str:D $keyword, %props, Bool :$cleanup = True --> BlockProps:D) {
    self.declare-block: :$id, :$keyword, :%props, :$cleanup
}
multi method declare-block(Pair:D (:key($id), :value($keyword)), %props, Bool :$cleanup = True --> BlockProps:D) {
    self.declare-block: :$id, :$keyword, :%props, :$cleanup
}
multi method declare-block(Str:D $keyword, %props, Bool :$cleanup = True --> BlockProps:D) {
    self.declare-block: :$keyword, :%props, :$cleanup
}
multi method declare-block(Str:D $keyword, Bool :$cleanup = True, *%props --> BlockProps:D) {
    self.declare-block: :$keyword, :%props, :$cleanup
}
multi method declare-block(Any:D $id, Str:D $keyword, Bool :$cleanup = True, *%props --> BlockProps:D) {
    self.declare-block: :$id, :$keyword, :%props, :$cleanup
}
multi method declare-block(*%params) {
    self.declare-statement: 'block', |%params
}

proto method declare-blocks(| --> Nil) {*}
multi method declare-blocks(@blocks, Bool :$cleanup = True --> Nil) {
    # $id here is a generic term because it can be either a $keyword or a $id => $keyword pair
    for @blocks -> Pair:D (:key($id), Hash() :value($props)) {
        self.declare-block: $id, $props, :$cleanup
    }
}
multi method declare-blocks(*@list where { all .map(* ~~ Pair:D) }, Bool :$cleanup = True, *%named --> Nil) {
    samewith (|@list, |(%named.pairs)), :$cleanup
}
multi method declare-blocks(%blocks, Bool :$cleanup = True --> Nil) {
    samewith %blocks.pairs
}

proto method declare-option(|) {*}
multi method declare-option(Any:D $id, Str:D $keyword, %props, Bool :$cleanup = True --> OptionProps:D) {
    self.declare-option: :$id, :$keyword, :%props, :$cleanup;
}
multi method declare-option(Pair:D (:key($id), :value($keyword)), %props, Bool :$cleanup = True --> OptionProps:D) {
    self.declare-option: :$id, :$keyword, :%props, :$cleanup
}
multi method declare-option(Str:D $keyword, %props, Bool :$cleanup = True --> OptionProps:D) {
    self.declare-option: :$keyword, :%props, :$cleanup
}
multi method declare-option(Str:D $keyword, Bool :$cleanup = True, *%props --> OptionProps:D) {
    self.declare-option: :$keyword, :%props, :$cleanup
}
multi method declare-option(*%params --> OptionProps:D) {
    self.declare-statement: 'option', |%params
}

proto method declare-options(| --> Nil) {*}
multi method declare-options(@options, Bool :$cleanup = True --> Nil) {
    # $id here is a generic term because it can be either a $keyword or a $id => $keyword pair
    for @options -> Pair:D (:key($id), Hash() :value($props)) {
        self.declare-option: $id, $props, :$cleanup;
    }
}
multi method declare-options(*@list where { all .map(* ~~ Pair:D) }, Bool :$cleanup = True, *%named --> Nil) {
    samewith (|@list, |(%named.pairs)), :$cleanup
}
multi method declare-options(%options, Bool :$cleanup = True --> Nil) {
    samewith %options.pairs, :$cleanup
}

method file {
    (!$*CFG-GRAMMAR || self === $*CFG-GRAMMAR) ?? $!file !! $*CFG-GRAMMAR.file
}

method line(:$absolute) {
    self.prematch.split(/\n/).elems - ($absolute ?? 0 !! $*CFG-GRAMMAR.line-delta)
}

my atomicint $decl-id = 0;
method autogen-id {
    ".auto-" ~ ++⚛$decl-id
}

method enter-ctx(Value:D :$keyword, Str:D :$type, *%profile --> Context:D) {
    self.panic: Config::BINDish::X::Parse::ContextOverwrite, :ctx($_) with $*CFG-CTX;
    my ::?CLASS:D $grammar = $*CFG-GRAMMAR;
    my Context $parent-ctx = $_ with $*CFG-PARENT-CTX;
    # Make calling code life easier by allowing :props to be an undefined value.
    %profile<props>:delete without %profile<props>;
    my %auto-profile;
    unless %profile<id> {
        # Try to determine ID based on type, keyword, and current parent
        my $kwd = $keyword.coerced;
        my $id;
        my StatementProps $props;
        if $kwd ∈ $grammar.keywords{$type} {
            # We do have a pre-declaration for this keyword. Try to locate it's properties for finding out its ID
            for $parent-ctx.cur-block-ctx.id, ".ANYWHERE" -> $parent-id {
                with $grammar.prop-relations{$parent-id} andthen $_{$type} andthen $_{$kwd} {
                    $props = $_;
                }
                last if $props;
            }
            self.panic: Config::BINDish::X::Parse::Context,
                        :what($type),
                        :$keyword,
                        :ctx($parent-ctx) without $props;
            $id = $props.id;
        }
        else {
            # Use a fake ID for undeclared statements
            $id = self.autogen-id;
        }
        %auto-profile = :$id, :$props;
    }
    $*CFG-CTX =
        $grammar.context-type($type).new(
            :$keyword,
            :$type,
            |%auto-profile,
            |%profile,
            |(:parent($parent-ctx) with $parent-ctx)
            );
}

method leave-option { }

method backtrack-option {
    my $*CFG-BACKTRACK-OPTION = True;
    self.leave-option
}

method validate-option {
    my $grammar = $*CFG-GRAMMAR;
    my $keyword = $*CFG-KEYWORD.coerced;
    if $keyword ∈ $grammar.keywords<option> {
        my $ctx = $*CFG-CTX;
        my $blk-ctx = $ctx.cur-block-ctx;
        my StatementProps $props = $ctx.props;
        self.panic: X::Parse::Context, :what<option>, :keyword($keyword), :ctx($blk-ctx)
            unless $props.defined && $props ~~ $blk-ctx && !$blk-ctx.props.value-only;
        my $value = $*CFG-VALUE // Value.new: :type(Bool), :type-name('bool'), :payload<True>;
        unless $value ~~ $props {
            self.panic: X::Parse::ValueType, :what<option>, :keyword($*CFG-KEYWORD), :$ctx, :$value
        }
    }
    elsif $grammar.strict.options {
        self.panic: X::Parse::Unknown, :what<option>, :$keyword
    }
}

method validate-block {
    my $grammar = $*CFG-GRAMMAR;
    my $keyword = $*CFG-BLOCK-TYPE.coerced;
    if $keyword ∈ $grammar.keywords<block> {
        my $ctx = $*CFG-CTX;
        my $parent-ctx = $*CFG-PARENT-CTX;
        my StatementProps $props = $ctx.props;
        self.panic: X::Parse::Context, :what<block>, :$keyword, :ctx($parent-ctx)
            unless $props.defined && ($parent-ctx ~~ $props);
        with $props.named {
            self.panic: X::Parse::MissingPart, :what<name>, :block-spec($keyword)
                unless !$_ || $*CFG-BLOCK-NAME.defined;
            self.panic: X::Parse::ExtraPart, :what<name>, :block-spec($keyword)
                if !$_ && $*CFG-BLOCK-NAME.defined;
        }
        if $props.named {
            with $props.classified {
                self.panic: X::Parse::MissingPart,
                            :what<class>,
                            :block-spec( $keyword ~
                                         ~( $*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME.gist !! '' ) )
                    unless !$_ || $*CFG-BLOCK-CLASS.defined;
                self.panic: X::Parse::ExtraPart,
                            :what<class>,
                            :block-spec( $keyword ~
                                         ~( $*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME.gist !! '' ) )
                    if !$_ && $*CFG-BLOCK-CLASS.defined;
            }
        }
    }
    elsif $grammar.strict.blocks {
        self.panic: X::Parse::Unknown, :what('block type'), :keyword($keyword)
    }
}

method validate-value {
    my $ctx = $*CFG-CTX;
    my $props = $ctx.props;
    if $props.defined && $props ~~ ContainerProps {
        if $ctx ~~ Context::Block && $props.no-values {
            self.panic: Config::BINDish::X::Parse::NoValueBlock,
                :what($ctx.type.lc), :keyword($ctx.keyword), :$ctx
        }
        unless (my $value = $*CFG-VALUE) ~~ $props {
            self.panic: X::Parse::ValueType, :what($ctx.type.lc), :keyword($ctx.keyword), :$ctx, :$value
        }
    }
}

method leave-block { }

method backtrack-block {
    my $*CFG-BACKTRACK-BLOCK = True;
    self.leave-block;
}

proto method panic(|) {*}
multi method panic(Str:D $msg) {
    Config::BINDish::X::Parse::General.new(:cursor(self), :$msg).throw
}
multi method panic(Config::BINDish::X::Parse:U \ex, Str $msg?, *%p) {
    ex.new(:cursor(self), |(:$msg with $msg), |%p).throw
}

# Method must return configuration source to be included with `include` directive as a text chunk.
method include-source(IO:D(Str:D) $file, Match:D $cursor --> Str:D) {
    unless $file.e {
        fail X::FileNotFound.new(file => ~$file, :$cursor)
    }
    unless $file.r {
        fail X::FileOp.new(file => ~$file, :op('read from'), :$cursor)
    }
    $file.slurp
}

# ---------------- GRAMMAR RULES ----------------

token TOP(Bool :$as-include) {
    :my $*CFG-AS-INCLUDE = ?$as-include;
    :my $*CFG-GRAMMAR = self;
    :my $*CFG-FLAT-BLOCKS = self.flat;
    :my $*CFG-TOP; # The top AST node. Used by Actions
    :my $*CFG-TOP-CTX;
    :my $*CFG-INNER-PARENT;
    [
        <?{ $as-include }>
        $<body>=<.as-include>
      ]
    | [
        <?{ !$as-include }>
        $<body>=<.as-main>
      ]
}

token enter-TOP { <?> }

rule as-include {
    <.enter-TOP>
    <statement-list>
}

rule as-main {
    :my $*CFG-CTX;
    {
        $*CFG-TOP-CTX = self.enter-ctx: :type<block>,
                                        :id<.TOP>,
                                        :keyword(Value.new: :payload<.TOP>,
                                                            :type(Str),
                                                            :type-name<keyword>);
    }
    <.enter-TOP>
    <statement-list>
}

rule statement-list {
    <?>
    [
    | $
    | <?before '}'>
    | [ $<statements>=<.statement> || <bad-statement> ]*? <?before '}' | $>
    ]
}

proto token statement {*}

multi rule statement:sym<include> {
    :my $*CFG-VALUE;
    :my $*CFG-INC-STMTS;
    $<err-pos>=<?> include <value> <?before <.statement-terminator>> <statement-terminate>
    {
        my $grammar = $*CFG-GRAMMAR;
        $*CFG-INC-STMTS = $*CFG-GRAMMAR.WHAT.parse:
            self.include-source(Str($<value>.ast), $<err-pos>),
            :file(~$<value>),
            actions => $.actions.WHAT,
            strict => $grammar.strict,
            flat => $grammar.flat,
            blocks => $grammar.blocks,
            options => $grammar.options,
            args => \(:as-include),
        ;
    }
}

multi token statement:sym<comment> {
        | <C-comment>
        | <CPP-comment>
        | <UNIX-comment>
}

# A string, number, boolean, or any user-defined type.
multi rule statement:sym<value> {
    :my Value $*CFG-VALUE;
    $<err-pos>=<?> $<value>=<.maybe-specific-value("block")> <statement-terminate>
    { $<err-pos>.validate-value }
}

token option-name {
    <keyword> <?before \s || <.statement-terminator>>
}

multi rule statement:sym<option> {
    :my Value $*CFG-KEYWORD;
    :my Value $*CFG-VALUE;
    :my Context:D $*CFG-PARENT-CTX = $*CFG-CTX;
    :temp $*CFG-CTX = Nil;
    :temp $*CFG-INNER-PARENT;
    $<err-pos>=<?> <option-name>
    <?{ ! $*CFG-GRAMMAR.is-reserved(option => $*CFG-KEYWORD.coerced) }>
    {
        $<err-pos>.enter-ctx: :type<option>,
                        :keyword( $*CFG-KEYWORD )
    }
    <.enter-option>
    [
        $<option-value>=<.maybe-specific-value("option")>?
        <?before <.statement-terminator>>
        <statement-terminate>
        <?{ # Inside a value-only block we skip boolean-only option because it will be re-parsed as a keyword.
            # But options with a value must cause a panic.
            my $ctx = $*CFG-CTX.cur-block-ctx;
            my $ok = True;
            if $ctx.props andthen .value-only {
                $<err-pos>.panic( X::Parse::Context,
                                  :what<option>,
                                  :keyword($*CFG-KEYWORD),
                                  :$ctx ) with $<option-value>;
                $ok = False;
            }
            $ok
        }>
        {
            $<err-pos>.validate-option;
            self.leave-option;
        }
    ]
    || <?{
        self.backtrack-option with $*CFG-KEYWORD;
        False
    }>
}

multi rule statement:sym<block> {
    :my Value $*CFG-BLOCK-TYPE;
    :my Value $*CFG-BLOCK-NAME;
    :my Value $*CFG-BLOCK-CLASS;
    :my $*CFG-BLOCK-ERR-POS;
    :my Context:D $*CFG-PARENT-CTX = $*CFG-CTX;
    :temp $*CFG-CTX = Nil;
    :temp $*CFG-INNER-PARENT;
    $<err-pos>=<?> { $*CFG-BLOCK-ERR-POS = $<err-pos> }
    <block-head>
    [ <block-body> || <?{ self.backtrack-block; False }> ]
}

multi rule statement:sym<empty> {
    <?after <.statement-terminator>> ';'
}

token statement-terminator {
    [
    | [ <.ws> $ ]
    | [ <.ws> <?before '}'> ]
    | [ <?after '}'> <.ws> $<terminator>=';'? ]
    | [ <.ws> $<terminator>=';' ]
    ]
}

token statement-terminate {
    <statement-terminator>
    {
        unless !$*CFG-GRAMMAR.strict.syntax
               || ($<statement-terminator>
                   && $<statement-terminator><terminator>
                   && ~$<statement-terminator><terminator> eq ';')
        {
            self.panic: "Missing semicolon"
        }
    }
}

token bad-statement {
    <?> <.panic: "Unrecognized statement">
#    [ .*? [ ';' || $$ || '}' ] ] <.panic: "Unrecognized statement">
}

token enter-option { <?> }

token block-head {
    :my Value $*CFG-KEYWORD;
    $<block-type>=<.keyword> <.ws>
    <?{ ! $*CFG-GRAMMAR.is-reserved(block => $*CFG-KEYWORD.coerced) }>
    { $*CFG-BLOCK-TYPE = $*CFG-KEYWORD }
    [ <block-name> <.ws> [<block-class> <.ws>]? ]?
    <?before '{'>
    <.enter-block>
}

token block-name {
    :my Value $*CFG-VALUE;
    <value> { $*CFG-BLOCK-NAME = $*CFG-VALUE }
}

token block-class {
    :my Value $*CFG-KEYWORD;
    :my Value $*CFG-VALUE;
      $<class>=<.value>    { $*CFG-BLOCK-CLASS = $*CFG-VALUE }
    | $<class>=<.keyword>  { $*CFG-BLOCK-CLASS = $*CFG-KEYWORD }
}

token block-body {
    [ '{' <.ws> ] ~ [ <.ws> '}' <.statement-terminate> ]
    <statement-list>
    { self.leave-block }
}

token enter-block {
    <?>
    {
        my $block-type = $*CFG-BLOCK-TYPE;
        self.enter-ctx:
            :type<block>,
            :keyword( $block-type ),
            :name( $*CFG-BLOCK-NAME ),
            :class( $*CFG-BLOCK-CLASS );
        $*CFG-BLOCK-ERR-POS.validate-block;
    }
}

token C-comment {
    '/*' ~ '*/' $<comment-body>=.*?
}

token CPP-comment {
    '//' $<comment-body>=.*? $$
}

token UNIX-comment {
    [ ^^ '#line' <.ws>
        $<line>=\d+ { self.set-line-relative: Int($<line>) }
        [ <.ws>
          \" ~ \" $<file>=<.qstring('"')> { $*CFG-GRAMMAR.set-file($<file>.caps.map(*.value).join) } ]?
        \s*? $$ ]
    || [ '#' $<comment-body>=.*? $$ ]
}

token keyword {
    <.wb> $<kwd>=[ <.alpha> [ \w | '-' ]* ] <.wb>
    { $*CFG-KEYWORD = Value.new: :type(Str), :type-name<keyword>, :payload($/) }
}

token bool-true {
    yes | on | true
}
token bool-false {
    no | off | false
}

token boolean {
    <.wb> [<bool-true> | <bool-false>] <.wb>
}

token qstring($quote) {
    [ [ $<chunk>=<{ '<-[ \\\\ ' ~ $quote ~ ' ]>+'  }> ] | [ \\ $<char>=. ] ]*? <?before $($quote)>
}

token dq-string {
    \" ~ \" $<string>=<.qstring('"')> { self.set-value: Str, :dq-string($<string>) }
}
token sq-string {
    \' ~ \' $<string>=<.qstring("'")> { self.set-value: Str, :sq-string($<string>) }
}

token decimal($max = 9) {
    [ <{"<[0..$max]>"}>+ ]+ % '_'
}
token heximal {
    [ <xdigit>+ ]+ % '_'
}

token natural_num {
    [
        | [ 0 <?before <[bodx]>>: [
                | [ b <decimal(1)> ]
                | [ o <decimal(7)> ]
                | [ d <decimal> ]
                | [ x <heximal> ]
            ] ]
        | <decimal>
    ]
}

token num_suffix {
    <?after <xdigit>> <[KkMmGgTtPp]>
}

method maybe-specific-value(Str:D $what --> Mu) is raw {
    # A value cannot start with a comment-like sequence.
    return self.new(:$.from, to => -3) if self.postmatch.starts-with('#' | '//' | '/*');
    my $ctx = $*CFG-CTX;
    my $props = $ctx.props;
    with $props {
        if $props ~~ ContainerProps && $ctx.props.value-sym {
            for $props.value-sym<> -> $sym {
                # Make it possible for value parsers to know they're expected.
                my $*CFG-SPECIFIC-VALUE-SYM = $sym;
                with self."value:sym<$sym>"() {
                    return $_ if $_;
                }
            }
            # We either have a non-value or a wrong value type. Try parsing as an option first if current context is a
            # value-only block as the rule would throw correct context exception then.
            my $expected-specific = $ctx ~~ Context::Option && $ctx.props.value-sym;
            if !$expected-specific && $ctx ~~ Context::Block && $ctx.props.value-only {
                self."statement:sym<option>"();
                $expected-specific = True;
            }
            self.panic: X::Parse::SpecificValue, :$what, :$ctx, :keyword( $ctx.keyword ) if $expected-specific;
            return self.new(:$.from, to => -3);
        }
    }
    self.value
}

proto token value {*}
multi token value:sym<string> {
    <dq-string> | <sq-string>
}

multi token value:sym<bool> {
    # Make sure we don't parse for pre-declared non-boolean containers
    <?{ (my $ctx = $*CFG-CTX)
        && (!$ctx.props.defined || $ctx.props.can-type('bool', Bool)) }>
    <boolean> { self.set-value: Bool, :bool($/) }
}

multi token value:sym<keyword> {
    <?{ (my $ctx = $*CFG-CTX) and
        (($ctx ~~ Context::Option)
         || ($ctx.cur-block-ctx.props andthen .value-only)) }>
    :my Value $*CFG-KEYWORD;
    [
        <?{ $*CFG-SPECIFIC-VALUE-SYM andthen $_ eq 'keyword' }> <keyword>
        | <!before <.boolean>> <keyword>
    ]
    { $*CFG-GRAMMAR.set-value: Str, :keyword($*CFG-KEYWORD.payload) }
}

multi token value:sym<num> {
    $<err-pos>=<?before <[-+]>? [\d | '.' \d]>
    $<sign>=<[-+]>? [
        | [ $<int>=\d* '.' $<frac>=\d+ ]
        | [ $<int>=\d+ ]
    ]
    e $<exp>=[<[-+]>? \d+] <.wb> { self.set-value: Num, :num($/) }
}

multi token value:sym<rat> {
    $<err-pos>=<?before <[-+]>? [\d | '.' \d]>
    $<sign>=<[-+]>? [
        | [ $<numerator>=<.decimal> '.' <!before <.decimal>> ]
        | [ [ $<numerator>=<.decimal>? '.' $<denominator>=<.decimal> ]
            <num_suffix>? <.wb> ]
    ]
    { self.set-value: Rat, :rat($/) }
}

multi token value:sym<int> {
    $<err-pos>=<?before <[-+]>? \d>
    [ $<icard>=[ <[-+]>?: <natural_num> ]
        [ [<num_suffix>? <.wb> ]
          | { $<err-pos>.panic: X::Parse::BadNum } ]
    ]
    <!before <[.e]>>
    { self.set-value: Int, :int($/) }
}

token path-component {
    <[\N] - [;/]>+
}
multi token value:sym<file-path> {
    :my Value $*CFG-KEYWORD;
    [
        | [['.' | '..' ]? '/' <.path-component>* %% '/']
        | [ <?{ $*CFG-SPECIFIC-VALUE-SYM andthen $_ eq 'file-path' }>
            # Option-like looking path is only accepted when:
            # - it's an option value
            # - it belongs to a value-only block
            [ <?{ $_ ~~ Context::Option || .cur-block-ctx.props.value-only with $*CFG-CTX }>
            | <!before <.option-name>> ]
            <.path-component>+ %% '/' ]
    ]
    { self.set-value: Str, :file-path($/) }
}