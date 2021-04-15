use v6.d;
#no precompilation;
#use Grammar::Tracer;
use nqp;
unit grammar Config::BINDish::Grammar;
use Config::BINDish::X;

class Context {...}

class Value {
    has Str:D $.type-name is required;
    has Mu $.type is required;
    has Mu $.value is required;

    method gist {
        my $val = Str($!value);
        my $quote = $!type-name eq 'dq-string' ?? '"' !! "'";
        $!type ~~ Stringy ?? $quote ~ $val ~ $quote !! $val
    }

    method coerced(::?CLASS:D:) {
        -> ::T { T($!payload) }($!type)
    }
}

role StatementProps {
    # If non-empty then this statement can only be contained by blocks listed here.
    has SetHash:D() $.in = ();
    # If statement can only be declared at the top level
    has Bool:D $.top-only = False;

    multi method COERCE(%profile) {
        self.new: |%profile
    }

    multi method ACCEPTS(Context:D $ctx) {
        my $cur-block = $ctx.cur-block-ctx;
        return $cur-block.type eq 'TOP' if $!top-only;
        $!in ?? ( $cur-block.keyword && $cur-block.keyword.value ∈ $!in) !! True
    }
}

role ContainerProps {
    # These attributes are used as RHS of a smartmatch.
    # NOTE: These are kept separate from StatementProps because extensions may add non-container type statements.
    has $.type-name;
    has Mu $.type;

    multi method ACCEPTS(Value:D $val) {
        (!$!type-name.defined || $val.type-name ~~ $!type-name)
        && ($!type =:= Mu || $val.type ~~ $!type)
    }

    method type-as-str {
        ($!type-name ~ " of " with $!type-name) ~ $!type.gist
    }
}

class OptionProps does StatementProps does ContainerProps {}

class BlockProps does StatementProps does ContainerProps {
    # Block must be named
    has Bool:D $.named = False;
    # Block must have a class
    has Bool:D $.classified = False;
    # Block can only contain values, no options or blocks allowed
    has Bool:D $.value-only = False;
}

class Context {
    # Type of statement (keyword).
    has Value $.keyword;
    has Value $.name;
    # Context type. "TOP", "BLOCK", "OPTION", or a user-defined
    has Str:D $.type is required;
    has StatementProps $.props;
    has ::?CLASS $.parent;

    method parent(Int:D $count = 0 --> ::?CLASS:D) {
        return $!parent unless $count;
        $!parent.parent($count - 1)
    }

    method cur-block-ctx(--> Context) {
        return self if $!type eq 'TOP' | 'BLOCK';
        $!parent.cur-block-ctx
    }

    method description {
        given $!type {
            when 'TOP'    { 'global context' }
            when 'BLOCK'  { "block '" ~ $!keyword.value ~ ($!name ?? " " ~ $!name.gist !! "") ~ "'" }
            when 'OPTION' { "option '" ~ $!keyword.value ~ "'" }
            default {
                die "Internal: looks like " ~ $_ ~ " context hasn't been given a description!"
            }
        }
    }
}

class Strictness {
    has Bool:D $.syntax = False;
    has Bool:D $.options = False;
    has Bool:D $.blocks = False;
    multi method COERCE(Hash:D $p) { self.new: |$p }
    multi method COERCE(Pair:D $p) { self.new: |$p }
    multi method COERCE(Positional:D $l where { ? all .map(* ~~ Pair) }) { self.new: |%$l }
    multi method COERCE(Bool:D $default) { self.new: :syntax($default), :options($default), :blocks($default) }
}

has Bool:D $.flat = False;
has Strictness:D() $.strict = False;
# All block types.
has BlockProps() %.blk-props;
# Allowed top-level keywords.
has OptionProps() %.opt-props;
# User-defined blocks and options, set-only.
has %.blocks;
has %.options;

# Context stack. Normally a new context is created on per-parent basis.
has @.contexts;

method set-value(Mu $type is raw, *%tinfo where *.elems == 1 --> Value:D) {
    my ($type-name, $value) = %tinfo.kv;
    $*CFG-VALUE = Value.new: :$type, :$value, :$type-name
}

submethod TWEAK(|) {
    # Walk over grammar's MRO and invoke setup methods.
    # To prevent duplicate iteration over submethods defined in v6.c/v6.d roles
    # record submethod objects we've already invoked.
    my %invoked;
    for self.^mro(:roles) -> \component {
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

submethod setup-BINDish {
    self.declare-blocks: %!blocks;
    self.declare-options: %!options;
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

proto method declare-blocks(|) {*}
multi method declare-blocks(%blocks) {
    for %blocks.kv -> $name, %props {
        die "Re-declaration of block '$name'"
            with %!blk-props{$name};
        %!blk-props{$name} = BlockProps.new: |%props;
    }
}
multi method declare-blocks(*%blocks) {
    samewith(%blocks);
}

proto method declare-options(|) {*}
multi method declare-options(%options) {
    for %options.kv -> $name, %props {
        die "Re-declaration of option '" ~ $name ~ "'"
            with %!opt-props{$name};
        %!opt-props{$name} = OptionProps.new: |%props;
    }
}
multi method declare-options(*%options) {
    samewith(%options)
}

method cfg-ctx {
    self === $*CFG-GRAMMAR ?? @!contexts[*-1] !! $*CFG-GRAMMAR.cfg-ctx
}

method push-ctx(|c(*%profile) --> Context:D)
{
    return $*CFG-GRAMMAR.push-ctx(|c) unless self === $*CFG-GRAMMAR;
    my Context $parent;
    $parent = @!contexts[*-1] if @!contexts;
    # Make code like easier by allowing :props to be an undefined value.
    %profile<props>:delete without %profile<props>;
    @!contexts.push: my $cur = Context.new(|%profile, :$parent);
    $cur
}

method pop-ctx(--> Context:D) {
    return $*CFG-GRAMMAR.pop-ctx unless self === $*CFG-GRAMMAR;
    die "Attempted to pop the top context" if @!contexts[*-1].type eq 'TOP';
    @!contexts.pop
}

method block-ok(Str:D $type) {
    my %blocks = $*CFG-GRAMMAR.blk-props;
    return True unless %blocks;
    with %blocks{$type} {
        return self.cfg-ctx ~~ $_
    }
    False
}

method option-ok(Str:D $keyword) {
    my %options = $*CFG-GRAMMAR.opt-props;
    return True unless %options;
    with %options{$keyword} {
        return self.cfg-ctx ~~ $_
    }
    False
}

method enter-option {
    self.push-ctx: :type<OPTION>,
                   :props( %!opt-props{$*CFG-KEYWORD.value} ),
                   :keyword( $*CFG-KEYWORD )
}

method leave-option {
    self.pop-ctx
}

method backtrack-option {
    self.leave-option
}

method validate-option {
    my ::?CLASS:D $grammar = $*CFG-GRAMMAR;
    my %options = $grammar.opt-props;
    if %options {
        my $ctx = self.cfg-ctx.cur-block-ctx;
        my $keyword = $*CFG-KEYWORD.value;
        my $props = %options{$keyword};
        if $props {
            self.panic: X::Parse::Context, :what<option>, :keyword($*CFG-KEYWORD), :$ctx
                unless self.option-ok($keyword) && !$ctx.props.value-only;
            my $value = $*CFG-VALUE // Value.new: :type(Bool), :type-name('bool'), :value;
            unless $value ~~ $props {
                self.panic: X::Parse::ValueType, :what<option>, :keyword($*CFG-KEYWORD), :$props, :$value
            }
        }
        elsif $grammar.strict.options {
            self.panic: X::Parse::Unknown, :what<option>, :$keyword
        }
    }
    self.leave-option
}

method validate-block {
    my $ctx = self.cfg-ctx;
    my $grammar = $*CFG-GRAMMAR;
    my Str:D $block-type = $*CFG-BLOCK-TYPE.value;
    my StatementProps $props;
    my %blocks = $*CFG-GRAMMAR.blk-props;
    if %blocks {
        $props = $_ with %blocks{$block-type};
        if $props {
            self.panic: X::Parse::Context, :what<block>, :keyword($*CFG-BLOCK-TYPE), :$ctx
                unless self.block-ok($block-type);
            self.panic: X::Parse::MissingPart, :what<name>, :block-spec($block-type)
                unless !$props.named || $*CFG-BLOCK-NAME;
            self.panic: X::Parse::MissingPart,
                        :what<class>,
                        :block-spec($block-type ~
                                    ~ ($*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME !! ''))
                unless !$props.classified || $*CFG-BLOCK-CLASS;
        }
        elsif $grammar.strict.blocks {
            self.panic: X::Parse::Unknown, :what('block type'), :keyword($block-type)
        }
    }
    self.push-ctx: :type<BLOCK>, :keyword( $*CFG-BLOCK-TYPE ), :name( $*CFG-BLOCK-NAME ), :$props;
}

method validate-value {
    my $ctx = self.cfg-ctx;
    my $props = $ctx.props;
    if $props && $props ~~ ContainerProps {
#        my $grammar = $*CFG-GRAMMAR;
        unless (my $value = $*CFG-VALUE) ~~ $props {
            self.panic: X::Parse::ValueType, :what($ctx.type.lc), :keyword($ctx.keyword), :$props, :$value
        }
    }
}

method leave-block { self.pop-ctx }

method block-description {
    $*CFG-BLOCK-TYPE
        ?? ($*CFG-BLOCK-TYPE
            ~ ($*CFG-BLOCK-NAME
                ?? " " ~ $*CFG-BLOCK-NAME
                !! ""))
        !! "*global context*"
}

proto method panic(|) {*}
multi method panic(Str:D $msg) {
    Config::BINDish::X::Parse::General.new(:cursor(self), :$msg).throw
}
multi method panic(Config::BINDish::X::Parse:U \ex, Str $msg?, *%p) {
    ex.new(:cursor(self), |(:$msg with $msg), |%p).throw
}

# ---------------- GRAMMAR RULES ----------------
rule TOP {
    :my $*CFG-GRAMMAR = self;
    :my $*CFG-FLAT-BLOCKS = self.flat;
    :my $*CFG-INNER-PARENT;
    :my $*CFG-TOP;
    <.enter-TOP>
    {
        self.push-ctx: :type<TOP>,
                       :props(BlockProps.new),
                       :keyword(Value.new: :value<TOP>, :type(Str), :type-name<keyword>);
    }
    <statement-list>
}

token enter-TOP { <?> }

rule statement-list {
    <?>
    [
    | $
    | <?before '}'>
    | [ $<statements>=<.statement> || <bad-statement> ]*? <?before '}' | $>
    ]
}

proto token statement {*}
multi token statement:sym<comment> {
        | <C-comment>
        | <CPP-comment>
        | <UNIX-comment>
}

# A string, number, boolean, or any user-defined type.
multi rule statement:sym<value> {
    :my Value $*CFG-VALUE;
    $<err-pos>=<?> <value> <statement-terminate>
    { $<err-pos>.validate-value }
}

multi rule statement:sym<option> {
    :my $*CFG-KEYWORD;
    :my Value $*CFG-VALUE;
    $<option-name>=<.keyword>
    { self.enter-option }
    [
    [$<option-value>=<.value> ]?
        <?before <.statement-terminator>>
        $<err-pos>=<?> <statement-terminate>
        { $<err-pos>.validate-option }
    ]
    | <?{
        self.backtrack-option with $*CFG-KEYWORD;
        False
    }>
}

multi rule statement:sym<block> {
    :my Value $*CFG-BLOCK-TYPE;
    :my Value $*CFG-BLOCK-NAME;
    :my Value $*CFG-BLOCK-CLASS;
    :my $*CFG-BLOCK-ERR-POS;
    $<err-pos>=<?> { $*CFG-BLOCK-ERR-POS = $<err-pos> }
    <block-head>
    [ <block-name> <block-class>? ]?
    <?before '{'>
    <block-body>
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
        { self.panic: "Missing semicolon" }
    }
}

token bad-statement {
    <?> <.panic: "Unrecognized statement">
#    [ .*? [ ';' || $$ || '}' ] ] <.panic: "Unrecognized statement">
}

token block-head {
    :my Value $*CFG-KEYWORD;
    $<block-type>=<.keyword> { $*CFG-BLOCK-TYPE = $*CFG-KEYWORD }
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
    :temp $*CFG-INNER-PARENT;
    [ '{' <.ws> ] ~ [ <.ws> '}' <.statement-terminate> ]
    [
        { $*CFG-BLOCK-ERR-POS.validate-block }
        <.enter-block>
        <statement-list>
    ]
    { self.leave-block }
}

token enter-block { <?> }

token C-comment {
    '/*' ~ '*/' $<comment-body>=.*?
}

token CPP-comment {
    '//' $<comment-body>=.*? $$
}

token UNIX-comment {
    '#' $<comment-body>=.*? $$
}

token keyword {
    <.alpha> [ \w | '-' ]* { $*CFG-KEYWORD = Value.new: :type(Str), :type-name<keyword>, :value(~$/) }
}

token bool-true {
    yes | on | true
}
token bool-false {
    no | off | false
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

proto token value {*}
multi token value:sym<string> {
    <dq-string> | <sq-string>
}
multi token value:sym<num> {
    <[-+]>? [
        | [ \d* '.' \d+ ]
        | [ \d+ ]
    ]
    e <[-+]>? \d+ <.wb> { self.set-value: Num, :num($/) }
}
multi token value:sym<rat> {
    <[-+]>? [
        | [ $<numerator>=\d* '.' $<denominator>=\d+ <.wb> ]
        | [ $<numerator>=\d+ '.' <!before \d> ]
    ] { self.set-value: Rat, :rat($/) }
}
multi token value:sym<int> {
    <[-+]>? \d+ <!before <[.e]>> { self.set-value: Int, :int($/) }
}
multi token value:sym<bool> {
    $<bool-val>=[ <.bool-true> | <.bool-false> ] { self.set-value: Bool, :bool($/) }
}