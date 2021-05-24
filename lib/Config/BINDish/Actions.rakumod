use v6.d;
unit class Config::BINDish::Actions;

use Config::BINDish::AST;
use Config::BINDish::X;

method TOP($/) {
    my $top = self.inner-parent;
    if $<statement-list><statements> {
        for $<statement-list><statements> -> $stmt {
            $top.add: $stmt.ast;
        }
    }
    make $top;
}

method enter-TOP($) {
    $*CFG-TOP = self.enter-parent: Config::BINDish::AST.new-ast('TOP');
}

method statement:sym<value>($/) {
    make $<value>.ast
}

method statement:sym<comment>($/) {
    make $/.chunks[0].value.ast;
}

method statement:sym<option>($/) {
    my $value;
    with $<option-value> {
        $value = .made;
    }
    else {
        $value = Config::BINDish::AST.new-ast('Value',
                                              :type(Bool),
                                              :type-name<bool>,
                                              :payload);
    }
    my $opt = Config::BINDish::AST.new-ast('Option',
                                           :keyword($<option-name>.made),
                                           :$value);
    make $opt;
}

method statement:sym<block>($/) {
    my $block = $<block-body>.ast;
    with $<block-name> {
        $block.set-name(.made);
    }
    with $<block-class> {
        $block.set-class(.made);
    }
    make $block;
}

method statement:sym<empty>($/) {
    make Config::BINDish::AST.new-ast('NOP');
}

method dq-string($/) {
    make Config::BINDish::AST.new-ast('Value', :payload($<string>.chunks.map(*.value).join), :type-name<dq-string>);
}

method sq-string($/) {
    make Config::BINDish::AST.new-ast('Value', :payload($<string>.chunks.map(*.value).join), :type-name<sq-string>);
}

our %multipliers = K => 1024, M => 1024², G => 1024³, T => 1024⁴, P => 1024⁵;

method num_suffix($/) {
    with %multipliers{$/.uc} {
        make $_
    }
    else {
        die "Unknown numeric suffix '$/'";
    }
}

method value:sym<string>($/) {
    with $<dq-string> {
        make .made;
    }
    orwith $<sq-string> {
        make .made;
    }
    else {
        $/.panic: "IMPOSSIBLE! but neither sq-string nor dq-string are found...";
    }
}

method value:sym<keyword>($/) {
    make Config::BINDish::AST.new-ast('Value', :payload(Str($*CFG-VALUE.payload)), :type-name<keyword>);
}

method value:sym<rat>($/) {
    my Int $multiplier = ($<num_suffix> andthen .made) || 1;
    my $icard = Rat($<sign>
                    ~ ($<numerator> || '0')
                    ~ '.'
                    ~ ($<denominator> || '0'));

    $<err-pos>.panic(X::Parse::BadNum) if $icard ~~ Failure;

    make Config::BINDish::AST.new-ast('Value', :payload($icard * $multiplier), :type-name<rat>);
}

method value:sym<int>($/) {
    my Int $multiplier = ($<num_suffix> andthen .made) || 1;
    my $icard = Int($<icard>);

    $<err-pos>.panic(X::Parse::BadNum) if $icard ~~ Failure;

    make Config::BINDish::AST.new-ast('Value', :payload($icard * $multiplier), :type-name<int>);
}

method value:sym<num>($/) {
    my $int = $<int> || '0';
    my $frac = $<frac> || '0';
    my $num = Num($int ~ '.' ~ $frac ~ 'e' ~ $<exp>);

    $<err-pos>.panic(X::Parse::BadNum) if $num ~~ Failure;

    make Config::BINDish::AST.new-ast('Value', :payload($num), :type-name<num>);
}

method value:sym<bool>($/) {
    make $<bool-val>.made
}

method value:sym<file-path>($/) {
    make Config::BINDish::AST.new-ast('Value', :payload(~$/), :type-name<file-path>)
}

method bool-true($/) {
    make Config::BINDish::AST.new-ast('Value', :payload, :type-name<bool>)
}

method bool-false($/) {
    make Config::BINDish::AST.new-ast('Value', :!payload, :type-name<bool>);
}

method C-comment($/) {
    make Config::BINDish::AST.new-ast('Comment',
                                      :family<C>,
                                      :body(~$<comment-body>))
}
method CPP-comment($/) {
    make Config::BINDish::AST.new-ast('Comment',
                                      :family<CPP>,
                                      :body(~$<comment-body>))
}

method UNIX-comment($/) {
    make Config::BINDish::AST.new-ast('Comment',
                                      :family<UNIX>,
                                      :body(~$<comment-body>));
}

method keyword($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type-name<keyword>,
                                      :payload(Str($*CFG-KEYWORD.payload)))
}

method block-class($/) {
    make $<class>.made
}

method block-name($/) {
    make $<value>.made
}

method block-head($/) {
    make $<block-type>.made
}

method enter-block($) {
    self.enter-parent: Config::BINDish::AST.new-ast('Block',
                                                    :keyword(self.make-container($*CFG-BLOCK-TYPE)));
}

method block-body($/) {
    my $block = self.inner-parent;

    if $<statement-list><statements> {
        for @($<statement-list><statements>) -> $st {
            $block.add: $st.ast;
        }
    }

    make $block;
}

# --- Utility methods

method make-container(Config::BINDish::Grammar::Value:D $gval) {
    Config::BINDish::AST::Value($gval)
}

proto method enter-parent(| --> Config::BINDish::AST::Parent:D) {*}
multi method enter-parent(Config::BINDish::AST::Parent:D $inner --> Config::BINDish::AST::Parent:D) {
    $*CFG-INNER-PARENT = $inner;
}
multi method enter-parent(Config::BINDish::AST::Parent:U $inner, |c --> Config::BINDish::AST::Parent:D) {
    $*CFG-INNER-PARENT = $inner.WHAT.new(|c)
}

method inner-parent {
    $*CFG-INNER-PARENT // X::NoInnerParent.new.throw
}