use v6.d;
use nqp;
#no precompilation;
#use Grammar::Tracer;
unit grammar Config::BINDish::Grammar;
use Config::BINDish::X;
use AttrX::Mooish;

class Context {...}

role StatementProps {
    # If non-empty then this statement can only be contained by blocks listed here.
    has SetHash:D() $.in = ();
    # If statement can only be declared at the top level
    has Bool:D $.top-only = False;

    multi method COERCE(%profile) {
        self.new: |%profile
    }
    multi method COERCE(Any) {
        self.new
    }
    multi method ACCEPTS(Context:D $ctx) {
        my $cur-block = $ctx.cur-block-ctx;
        return $cur-block.type eq 'TOP' if $!top-only;
        $!in ?? ( $cur-block.keyword && $cur-block.keyword.value ∈ $!in) !! True
    }
}

class OptionProps does StatementProps {
    # These attributes are used as RHS of a smartmatch.
    has Str $.type-name;
    has Mu $.type;
}

class BlockProps does StatementProps {
    # Block must be named
    has Bool:D $.named = False;
    # Block must have a class
    has Bool:D $.classified = False;
    # Block can only contain values, no options or blocks allowed
    has Bool:D $.value-only = False;
}

class Value {
    has Str:D $.type-name is required;
    has Mu $.type is required;
    has Mu $.value is required;

    method Str {
        my $val = Str($!value);
        $!type ~~ Stringy ?? '"' ~ $val ~ '"' !! $val
    }
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
            when 'BLOCK'  { "block '" ~ $!keyword.value ~ ($!name ?? " " ~ $!name !! "") ~ "'" }
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
    multi method COERCE(Hash:D %p) { self.new: |%p }
    multi method COERCE(Pair:D $p) { self.new: |$p }
    multi method COERCE(Positional:D $l where { ? all .map(* ~~ Pair) }) { self.new: |%$l }
    multi method COERCE(Bool:D $default) { self.new: :syntax($default), :options($default), :blocks($default) }
}

has Bool:D $.flat = False;
has Strictness:D() $.strict = False;
# All block types.
has BlockProps() %.blocks;
# Allowed top-level keywords.
has OptionProps() %.options;
has @.contexts;

method set-value(Mu $type is raw, *%tinfo where *.elems == 1 --> Value:D) {
    my ($type-name, $value) = %tinfo.kv;
    $*CFG-VALUE = Value.new: :$type, :$value, :$type-name
}

submethod TWEAK(|) {
    if 0 && $*RAKU.compiler.version >= v2021.03.20.g.776.f.1.a.626 {
        self.WALK(:name<setup-BINDish>, :!methods, :submethods, :roles).invoke.sink;
    }
    else {
        # Earlier versions of Rakudo had a bug in WALK which caused it to attempt submethod_table on NQP classes
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
}

submethod setup-BINDish {
    self.declare-blocks:
        block => { :top-only },
        subblock => { in => <block> },
        foo => { :named, :classified },
#        fubar => { :named, in => <block subblock> },
        ;
    self.declare-options:
        val => {},
        val2 => { type => Str },
        count => { in => <block>, type-name => 'int', },
        subval => { in => <subblock> },
        allow-something => { in => <block> },
        ;
}

proto method declare-blocks(|) {*}
multi method declare-blocks(%blocks) {
    for %blocks.kv -> $name, %props {
        die "Re-declaration of block '$name'"
            with %!blocks{$name};
        %!blocks{$name} = BlockProps.new: |%props;
    }
}
multi method declare-blocks(*%blocks) {
    samewith(%blocks);
}

proto method declare-options(|) {*}
multi method declare-options(%options) {
    for %options.kv -> $name, %props {
        die "Re-declaration of option '" ~ $name ~ "'"
            with %!options{$name};
        %!options{$name} = OptionProps.new: |%props;
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
    my %blocks = $*CFG-GRAMMAR.blocks;
    return True unless %blocks;
    with %blocks{$type} {
        return self.cfg-ctx ~~ $_
    }
    False
}

method option-ok(Str:D $keyword) {
    my %options = $*CFG-GRAMMAR.options;
    return True unless %options;
    with %options{$keyword} {
        return self.cfg-ctx ~~ $_
    }
    False
}

method enter-option {
    self.push-ctx: :type<OPTION>,
                   :props( %!options{$*CFG-KEYWORD.value} ),
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
    my %options = $grammar.options;
    if %options {
        my $ctx = self.cfg-ctx.cur-block-ctx;
        my $keyword = $*CFG-KEYWORD.value;
        my $props = %options{$keyword};
        if $props {
            self.panic: "Option '$keyword' cannot be used in " ~ $ctx.description
                unless self.option-ok($keyword);
            my $value = $*CFG-VALUE // Value.new: :type(Bool), :type-name('bool'), :value;
            my $type-matches = True;
            my Mu $got-type;
            my Mu $expected-type;
            with $props.type-name {
                $type-matches = $value.type-name ~~ $_;
                $got-type = $value.type-name.raku;
                $expected-type = $_.raku;
            }
            if $type-matches && $props.type !=:= Mu {
                $type-matches = $value.type ~~ $props.type;
                $got-type = $value.type.gist;
                $expected-type = $props.type.gist;
            }
            unless $type-matches {
                self.panic: "Option '$keyword' expects a value of type "
                            ~ $expected-type
                            ~ " but got "
                            ~ $got-type
            }
        }
        elsif $grammar.strict.options {
            self.panic: "Unknown option '" ~ $keyword ~ "' in " ~ $ctx.description
        }
    }
    self.leave-option
}

method validate-block {
    my $ctx = self.cfg-ctx;
    my $grammar = $*CFG-GRAMMAR;
    my Str:D $block-type = $*CFG-BLOCK-TYPE.value;
    my StatementProps $props;
    my %blocks = $*CFG-GRAMMAR.blocks;
    if %blocks {
        $props = $_ with %blocks{$block-type};
        if $props {
            self.panic: "Block '"
                        ~ $block-type
                        ~ "' cannot be declared in "
                        ~ $ctx.description
                unless self.block-ok($block-type);
            self.panic: "Name is missing in declaraion of block '" ~ $block-type ~ "'"
                unless !$props.named || $*CFG-BLOCK-NAME;
            self.panic: "Class is missing in a declaraion of block '"
                        ~ $block-type
                        ~ ($*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME !! '')
                        ~ "'"
                unless !$props.classified || $*CFG-BLOCK-CLASS;
        }
        elsif $grammar.strict.blocks {
            self.panic: "Unknown block type '" ~ $block-type ~ "'"
        }
    }
    self.push-ctx: :type<BLOCK>, :keyword( $*CFG-BLOCK-TYPE ), :name( $*CFG-BLOCK-NAME ), :$props;
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

method panic(Str:D $msg) {
    Config::BINDish::X::Parse.new(:cursor(self), :$msg).throw
}

# ---------------- GRAMMAR RULES ----------------
rule TOP {
    :my $*CFG-GRAMMAR = self;
    :my $*CFG-FLAT-BLOCKS = self.flat;
    :my $*CFG-INNER-PARENT;
    :my $*CFG-TOP;
    <.enter-TOP>
    { self.push-ctx: :type<TOP>; }
    <statement-list>
}

token enter-TOP { <?> }

rule statement-list {
    <?>
    [
    | $
    | <?before '}'>
    | [ $<statements>=<statement> || <bad-statement> ]*? <?before '}' | $>
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
    <value> <statement-terminate>
}

multi rule statement:sym<option> {
    :my $*CFG-KEYWORD;
    :my Value $*CFG-VALUE;
    $<option-name>=<.keyword>
    { self.enter-option }
    [
        [ $<option-value>=<.value> ]?
        <?before <.statement-terminator>>
        $<err-pos>=<?> <statement-terminate>
        { $<err-pos>.validate-option }
    ]
    | <?{ self.backtrack-option with $*CFG-KEYWORD; False }>
}

multi rule statement:sym<block> {
    :my Value $*CFG-BLOCK-TYPE;
    :my Value $*CFG-BLOCK-NAME;
    :my Value $*CFG-BLOCK-CLASS;
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
        unless !$*CFG-GRAMMAR.strict.syntax || (~$<statement-terminator><terminator> eq ';') {
            self.panic: "Missing semicolon"
        }
    }
}

token bad-statement {
    [ .*? [ ';' || $$ || '}' ] ] <.panic: "Unrecognized statement">
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
        {
            self.validate-block
        }
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
multi token value:sym<int> {
    ['-' | '+']? \d+ { self.set-value: Int, :int($/) }
}
multi token value:sym<bool> {
    $<bool-val>=[ <.bool-true> | <.bool-false> ] { self.set-value: Bool, :bool($/) }
}
