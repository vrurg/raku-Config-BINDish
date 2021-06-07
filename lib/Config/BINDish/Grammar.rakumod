use v6.d;

#no precompilation;
#use Grammar::Tracer;
use nqp;
unit grammar Config::BINDish::Grammar;
use Config::BINDish::X;

our @coercers;
BEGIN {
    # Get all suspected methods-coercers. A method is considered coercer if lexical named after the method name is
    # a typeobject.
    @coercers = (|Match.^methods(:all), |Str.^methods(:all))
                    .map(*.name)
                    .unique
                    .grep({ LEXICAL::{$_}:exists && !LEXICAL::{$_}.defined });
}

class Context {...}

role TypeStringify {
    method type-name {...}
    method type {...}

    method type-as-str(--> Str:D) {
        my @parts;
        with $.type-name {
            @parts.push: $_ ~~ Stringy ?? '<' ~ $_ ~ '>' !! .gist
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

    method gist(::?CLASS:D:) {
        my $val = Str($!payload);
        my $quote = $!type-name eq 'dq-string' ?? '"' !! "'";
        $!type ~~ Stringy ?? $quote ~ $val ~ $quote !! $val
    }

    method coerced(::?CLASS:D:) {
        -> ::T { T($!payload) }.($!type)
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
        $!in ?? ( $cur-block.keyword && Str($cur-block.keyword.payload) ∈ $!in) !! True
    }
}

role ContainerProps does TypeStringify {
    # A list of value token sym names allowed for this container. For example, an option can be limited to be a
    # value:sym<int> only.
    has List(Str) $.value-sym;
    # These attributes are used as RHS of a smartmatch.
    # NOTE: These are kept separate from StatementProps because extensions may add non-container type statements.
    has $.type-name;
    has Mu $.type;

    multi method ACCEPTS(Value:D $val) {
        (!$!type-name.defined || $val.type-name ~~ $!type-name)
        && ($!type =:= Mu || $val.type ~~ $!type)
    }
}

class OptionProps does StatementProps does ContainerProps {}

class BlockProps does StatementProps does ContainerProps {
    # Block must be named or is optional if not set
    has Bool $.named;
    # Block must have a class or is optional if not set
    has Bool $.classified;
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

    method parent(::?CLASS:D: Int:D $count = 0 --> ::?CLASS:D) {
        return $!parent unless $count;
        $!parent.parent($count - 1)
    }

    method cur-block-ctx(::?CLASS:D: --> Context) {
        return self if $!type eq 'TOP' | 'BLOCK';
        $!parent.cur-block-ctx
    }

    method description(::?CLASS:D:) {
        given $!type {
            when 'TOP'    { 'global context' }
            when 'BLOCK'  { "block '" ~ $!keyword.payload ~ ($!name.defined ?? " " ~ $!name.gist !! "") ~ "'" }
            when 'OPTION' { "option '" ~ $!keyword.payload ~ "'" }
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

# Where we read from
has $!file is built;
has Int:D $.line-delta = 0;
has Bool:D $.flat = False;
has Strictness:D() $.strict = False;
# All block types.
has BlockProps() %.blk-props;
# Allowed top-level keywords.
has OptionProps() %.opt-props;
# User-defined blocks and options, set-only.
has %.blocks;
has %.options;

has %.reserved-opts = :include;

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

method file {
    (!$*CFG-GRAMMAR || self === $*CFG-GRAMMAR) ?? $!file !! $*CFG-GRAMMAR.file
}

method line(:$absolute) {
    self.prematch.chomp.split(/\n/).elems - ($absolute ?? 0 !! $*CFG-GRAMMAR.line-delta)
}

method enter-ctx(|c(*%profile) --> Context:D)
{
    self.panic: Config::BINDish::X::Parse::ContextOverwrite, :ctx($_) with $*CFG-CTX;
    my Context $parent = $_ with $*CFG-PARENT-CTX;
    # Make code like easier by allowing :props to be an undefined value.
    %profile<props>:delete without %profile<props>;
    $*CFG-CTX = Context.new(|%profile, :$parent);
}

method block-ok(Str:D $type --> Bool:D) {
    my %blocks = $*CFG-GRAMMAR.blk-props;
    return True unless %blocks;
    with %blocks{$type} {
        return $*CFG-PARENT-CTX ~~ $_
    }
    False
}

method option-ok(Str:D $keyword --> Bool:D) {
    my %options = $*CFG-GRAMMAR.opt-props;
    return True unless %options;
    with %options{$keyword} {
        return $*CFG-CTX ~~ $_
    }
    False
}

method leave-option { }

method backtrack-option {
    my $*CFG-BACKTRACK-OPTION = True;
    self.leave-option
}

method validate-option {
    my ::?CLASS:D $grammar = $*CFG-GRAMMAR;
    my %options = $grammar.opt-props;
    if %options {
        my $ctx = $*CFG-CTX;
        my $blk-ctx = $ctx.cur-block-ctx;
        my $keyword = Str($*CFG-KEYWORD.payload);
        my $props = %options{$keyword};
        if $props {
            self.panic: X::Parse::Context, :what<option>, :keyword($*CFG-KEYWORD), :ctx($blk-ctx)
                unless self.option-ok($keyword) && !$blk-ctx.props.value-only;
            my $value = $*CFG-VALUE // Value.new: :type(Bool), :type-name('bool'), :payload<True>;
            unless $value ~~ $props {
                self.panic: X::Parse::ValueType, :what<option>, :keyword($*CFG-KEYWORD), :$ctx, :$value
            }
        }
        elsif $grammar.strict.options {
            self.panic: X::Parse::Unknown, :what<option>, :$keyword
        }
    }
    self.leave-option
}

method validate-block {
    my $grammar = $*CFG-GRAMMAR;
    my $ctx = $*CFG-CTX;
    my Str:D() $block-type = $*CFG-BLOCK-TYPE.payload;
    my StatementProps $props = $ctx.props;
    my %blocks = $*CFG-GRAMMAR.blk-props;
    if %blocks {
        with %blocks{$block-type} {
            self.panic: X::Parse::Context, :what<block>, :keyword($*CFG-BLOCK-TYPE), :ctx($*CFG-PARENT-CTX)
                unless self.block-ok($block-type);
            with $props.named {
                self.panic: X::Parse::MissingPart, :what<name>, :block-spec($block-type)
                    unless !$_ || $*CFG-BLOCK-NAME.defined;
                self.panic: X::Parse::ExtraPart, :what<name>, :block-spec($block-type)
                    if !$_ && $*CFG-BLOCK-NAME.defined;
            }
            if $props.named {
                with $props.classified {
                    self.panic: X::Parse::MissingPart,
                                :what<class>,
                                :block-spec( $block-type ~
                                             ~( $*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME.gist !! '' ) )
                        unless !$_ || $*CFG-BLOCK-CLASS.defined;
                    self.panic: X::Parse::ExtraPart,
                                :what<class>,
                                :block-spec( $block-type ~
                                             ~( $*CFG-BLOCK-NAME ?? " " ~ $*CFG-BLOCK-NAME.gist !! '' ) )
                        if !$_ && $*CFG-BLOCK-CLASS.defined;
                }
            }
        }
        elsif $grammar.strict.blocks {
            self.panic: X::Parse::Unknown, :what('block type'), :keyword($block-type)
        }
    }
}

method validate-value {
    my $ctx = $*CFG-CTX;
    my $props = $ctx.props;
    if $props && $props ~~ ContainerProps {
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
    :my $*CFG-TOP;
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
    <.enter-TOP>
    {
        self.enter-ctx: :type<TOP>,
                        :props(BlockProps.new),
                        :keyword(Value.new: :payload<TOP>, :type(Str), :type-name<keyword>);
    }
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
    $<err-pos>=include <value> <?before <.statement-terminator>> <statement-terminate>
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

multi rule statement:sym<option> {
    :my Value $*CFG-KEYWORD;
    :my Value $*CFG-VALUE;
    :my Context:D $*CFG-PARENT-CTX = $*CFG-CTX;
    :temp $*CFG-CTX = Nil;
    :temp $*CFG-INNER-PARENT;
    $<err-pos>=$<option-name>=<.keyword>
    <.enter-option>
    <?{ !$*CFG-GRAMMAR.reserved-opts{~$<option-name>} }>
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
        { $<err-pos>.validate-option }
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

token enter-option {
    <?>
    {
        self.enter-ctx: :type<OPTION>,
                        :props( $*CFG-GRAMMAR.opt-props{Str($*CFG-KEYWORD)} ),
                        :keyword( $*CFG-KEYWORD )
    }
}

rule block-head {
    :my Value $*CFG-KEYWORD;
    $<block-type>=<.keyword> { $*CFG-BLOCK-TYPE = $*CFG-KEYWORD }
    [ <block-name> <block-class>? ]?
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
        my StatementProps $props = $*CFG-GRAMMAR.blk-props{ ~$block-type };
        self.enter-ctx: :type<BLOCK>,
                        :keyword( $block-type ),
                        :name( $*CFG-BLOCK-NAME ),
                        :$props;
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

method maybe-specific-value(Str:D $what) {
    my $ctx = $*CFG-CTX;
    if $ctx.props ~~ ContainerProps && $ctx.props.value-sym {
        for $ctx.props.value-sym<> -> $sym {
            # Make it possible for value parsers to know they're expected.
            my $*CFG-SPECIFIC-VALUE-SYM = $sym;
            with self."value:sym<$sym>"() {
                return $_ if $_;
            }
        }
        self.panic: X::Parse::SpecificValue, :$what, :$ctx, :keyword($*CFG-KEYWORD)
    }
    return self.value
}

proto token value {*}
multi token value:sym<string> {
    <dq-string> | <sq-string>
}

multi token value:sym<keyword> {
    <?{ (my $ctx = $*CFG-CTX) and
        (($ctx.type eq 'OPTION')
         || ($ctx.cur-block-ctx.props andthen .value-only)) }>
    :my Value $*CFG-KEYWORD;
    <keyword> { $*CFG-GRAMMAR.set-value: Str, :keyword($*CFG-KEYWORD.payload) }
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

multi token value:sym<bool> {
    $<bool-val>=[ <.bool-true> | <.bool-false> ] { self.set-value: Bool, :bool($/) }
}

token path-component {
    <[\N] - [;/]>+
}
multi token value:sym<file-path> {
    [
        | [['.' | '..' ]? '/' <.path-component>* %% '/']
        | <?{ $*CFG-SPECIFIC-VALUE-SYM andthen $_ eq 'file-path' }> <.path-component>+ %% '/'
    ]
    { self.set-value: Str, :file-path($/) }
}