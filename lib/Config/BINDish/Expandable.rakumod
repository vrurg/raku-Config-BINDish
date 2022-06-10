use v6.d;
unit module Config::BINDish::Expandable;
use nqp;
use Config::BINDish;
use Config::BINDish::Grammar;
use Config::BINDish::AST;
use Config::BINDish::X;

role AST::Expandable does Config::BINDish::AST::Container {
    has Bool $.expanded = False;

    method !maybe-expand {
        unless $!expanded {
            my $exp = self.expand;
            if $exp ~~ Config::BINDish::AST::Container {
                self!SET-FROM-CONTAINER: $exp;
            }
            else {
                self!SET-FROM-PROFILE(
                    payload => $exp,
                    type => $exp.WHAT,
                    type-name => ($exp ~~ Stringy ?? 'dq-string' !! $exp.^name.lc));
            }
            $!expanded = True;
        }
    }
    method payload {
        self!maybe-expand;
        nqp::getattr(nqp::decont(self), ::?CLASS, '$!payload')
    }
    method type {
        self!maybe-expand;
        nqp::getattr(nqp::decont(self), ::?CLASS, '$!type')
    }
    method type-name {
        self!maybe-expand;
        nqp::getattr(nqp::decont(self), ::?CLASS, '$!type-name')
    }
    method expand(::?ROLE:D:) {...}
}

# Reference to a block.
class AST::BlkRef is Config::BINDish::AST::Node {
    has Config::BINDish::AST::Container $!keyword;
    has Config::BINDish::AST::Container $!name;
    has Config::BINDish::AST::Container $!class;

    method keyword(::?CLASS:D:) {
        $!keyword //= self.child('block-type');
    }
    method name(::?CLASS:D:) {
        $!name //= self.child('block-name');
    }
    method class(::?CLASS:D:) {
        $!class //= self.child('block-class');
    }

    method gist(::?CLASS:D: Bool() :$detailed = True) {
        self.keyword.gist(:$detailed)
        ~ (
            ("(" ~ .gist(:$detailed)
                ~ (", " ~ .gist(:$detailed) with self.class)
                ~ ")/") with self.name
        )
    }
}

# Reference to parent block
class AST::ParentBlk is Config::BINDish::AST {
    method gist { "../" }
}

# Reference to a option. $.keyword is all we need of it
class AST::OptRef is Config::BINDish::AST::Node {
    has Config::BINDish::AST::Container $!keyword;

    method keyword(::?CLASS:D:) {
        $!keyword //= self.child('keyword')
    }

    method gist(::?CLASS:D: Bool() :$detailed = True) {
        self.keyword.gist(:$detailed)
    }
}

# A macro is considered a node where children define path to an option which is always the last child.
class AST::Macro
    is Config::BINDish::AST::Node
    does AST::Expandable
{
    # The path is relative to the TOP AST node.
    has Bool:D $.from-top = False;

    method set-from-top(::?CLASS:D: Bool:D $!from-top) {}

    method expand(::?CLASS:D:) {
        # If not from-top then
        my $cur-blk = $!from-top ?? self.top-node !! self.parent(Config::BINDish::AST::Block);
        my $exp;
        for @.children -> $child {
            if $child.WHAT ~~ AST::BlkRef {
                my %bp;
                %bp<name> = .payload with $child.name;
                %bp<class> = .payload with $child.class;
                my $blk = $cur-blk.block($child.keyword, |%bp);
                with $blk {
                    $cur-blk = $blk;
                }
                else {
                    Config::BINDish::X::Block::DoesntExists.new(type => $child.keyword, |%bp).throw
                }
            }
            elsif $child.WHAT ~~ AST::ParentBlk {
                $cur-blk = $cur-blk.parent(Config::BINDish::AST::Block);
            }
            elsif $child.WHAT ~~ Config::BINDish::AST::Value {
                $exp = ~$child;
            }
            else {
                if (my $val := $cur-blk.get($child.keyword.Str)) === Nil {
                    Config::BINDish::X::Macro::DoesntExists.new(name => $child.keyword, what => 'Option').throw
                }
                else {
                    $exp = $val;
                }
            }
        }
        $exp
    }

    method gist(::?CLASS:D: :$detailed) {
        '{'
        ~ ('/' if $!from-top)
        ~ @.children[^(*-1)].map(*.gist(:$detailed)).join
        ~ @.children.tail.gist(:$detailed)
        ~ '}'
    }

    method Str {
        self!maybe-expand;
        Str($!payload)
    }
}

# String is a node where children are either values of Str/string type or AST::Macro.
class AST::String
    is Config::BINDish::AST::Node
    does AST::Expandable
{
    method expand(::?CLASS:D:) {
        my $exp-str = "";
        for @.children -> $child {
            if $child.WHAT ~~ Config::BINDish::AST::Value | AST::Macro {
                $exp-str ~= Str($child);
            }
            else {
                die "Unexpected AST of type " ~ .^name ~ " in expandable string";
            }
        }
        $exp-str
    }

    method gist(::?CLASS:D: Bool :$detailed = True) {
        @.children.map({ .gist(:!detailed) } ).join
    }

    multi method ACCEPTS(::?CLASS:D: $val) {
        self!maybe-expand;
        self.Config::BINDish::AST::Container::ACCEPTS($val)
    }

    method Str {
        self!maybe-expand;
        Str($!payload)
    }
}

#`<< Implementing macro in format:

'{' <option> '}'

Where <option> can be:

option – an option in the current block
block([block-name], [block-class]).option – an option in a block
block(...).subblock(...).option – an option in a subblock of a block

Prefixing a macro with '/' means using the root (*TOP*) block.

A block can be particularly identified with a name or a class. Both are optional except that class can only be used
with the name.

Example:

"{foo}"
"{/foo}"
"{subblock("Bar").opt-bar}"
"{/block.subblock("Bar").opt-bar}"
"almost like in BIND: {/zone("oopsie.oops", AAA).ns}"
>>

role Grammar is BINDish-grammar {
    token dq-string {
        \" ~ \" $<string>=<.expandable-string> { self.set-value: Str, :dq-string($<string>) }
    }

    token expandable-string {
        :temp $*CFG-INNER-PARENT;
        <.expandable-string-enter>
        [
            | $<chunks>=( $<chunk>=<-[ \\ \" { ]>+ )
            | $<chunks>=( \\ $<chunk>=. )
            | $<chunks>=( <expandable-macro> )
        ]*? <?before \">
    }

    token expandable-string-enter { <?> }

    token expandable-macro {
        :temp $*CFG-INNER-PARENT;
        '{' ~ '}'
        [
            <.expandable-macro-enter>
            [
                | \s* <?before '}'>
                | $<body>=(
                    $<from-top>='/'?
                    $<block-path>=<expandable-block-ref>*
                    <expandable-option>
                )
                | $<env>=( '$' $<name>=\w+ $<optional>='?'? <?before '}'> )
            ]
        ]
    }

    token expandable-macro-enter { <?> }

    token expandable-option {
        :my $*CFG-KEYWORD;
        :my $*CFG-VALUE;
        # An option is always the last element before the closing }
        <keyword> <?before <.ws> '}'>
    }

    token expandable-block-ref {
        :my $*CFG-KEYWORD;
        :my $*CFG-VALUE;
        [
            | $<parent-block>='..'
            | $<block-type>=<.keyword>
                [
                    '(' ~ ')'
                    [
                        <.ws>
                        [ $<block-name>=<.value> | $<block-name>=<.keyword> ]
                        [ <.ws> ',' <.ws> $<block-class>=<.keyword> ]?
                        <.ws>
                    ]
                ]?
        ]
        '/' # Block references always end with '.'
    }
}

role Actions is BINDish-actions {
    method dq-string($/) {
        make $<string>.ast
    }

    method expandable-string-enter($) {
        self.enter-parent: AST::String,
                           :payload(Str),
                           :type(Str),
                           :type-name<dq-string>;
    }

    method expandable-macro-enter($) {
        self.enter-parent: AST::Macro,
                           :payload(Any),
                           :type(Any),
                           :type-name<expandable-macro>;
    }

    method expandable-string($/) {
        my $str-ast = self.inner-parent;
        my Str $sq-str;
        my sub add-str {
            # Add collected string chunk to the children.
            with $sq-str {
                $str-ast.add:
                    Config::BINDish::AST.new-ast: 'Value',
                                                  :type(Str),
                                                  # Using sq-string because chunks are non-expandable by definition
                                                  :type-name('sq-string'),
                                                  :payload($sq-str<>);
                $sq-str = Nil;
            }
        }
        for $<chunks> -> $chunk {
            with $chunk<expandable-macro> {
                add-str;
                $str-ast.add: .ast;
            }
            else {
                # Join all string chunks and escaped chars in to a plain string.
                $sq-str = ($sq-str // "") ~ $chunk<chunk>;
            }
        }
        # Don't forget to add the trailing string chunk if there is any.
        add-str;
        make $str-ast;
    }

    method expandable-block-ref($/) {
        my %profile;
        with $<parent-block> {
            make AST::ParentBlk.new;
        }
        else {
            make my $blkref = AST::BlkRef.new(|%profile);
            $blkref.add: .ast.mark-as('block-type') with $<block-type>;
            $blkref.add: .ast.mark-as('block-name') with $<block-name>;
            $blkref.add: .ast.mark-as('block-class') with $<block-class>;
        }
    }

    method expandable-option($/) {
        make my $oref = AST::OptRef.new;
        $oref.add: $<keyword>.ast;
    }

    method expandable-macro($/) {
        my $macro = self.inner-parent;
        with $<body> {
            $macro.set-from-top: ? Str(.<from-top>);
            for .<block-path> {
                $macro.add: .ast;
            }
            $macro.add: .<expandable-option>.ast;
        }
        with $<env> {
            my $env-value = "";
            my $env-name = ~.<name>;
            if %*ENV{$env-name}:exists {
                $env-value = %*ENV{$env-name};
            }
            elsif .<optional> ne '?' {
                Config::BINDish::X::Macro::DoesntExists.new(
                    name => $env-name,
                    what => 'Environment variable' ).throw
            }
            $macro.add:
                Config::BINDish::AST.new-ast: 'Value',
                    :type(Str),
                    :type-name('sq-string'),
                    :payload($env-value);
        }
        make $macro;
    }
}