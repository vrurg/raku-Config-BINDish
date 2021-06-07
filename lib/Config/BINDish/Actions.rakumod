use v6.d;
unit class Config::BINDish::Actions;

use Config::BINDish::AST;
use Config::BINDish::X;

method TOP($/, |c) {
    my $top = $*CFG-TOP;
    if $<body><statement-list><statements> {
        for $<body><statement-list><statements> -> $stmt {
            $top.add: $stmt.ast;
        }
    }
    make $top;
}

method enter-TOP($) {
    # If the source parsed is included from another config then we must produce just a list of statements.
    $*CFG-TOP = self.enter-parent:
                    Config::BINDish::AST.new-ast:
                        $*CFG-AS-INCLUDE ?? 'Stmts' !! 'TOP'
}

method statement:sym<value>($/) {
    make $<value>.ast.mark-as("standalone")
}

method statement:sym<comment>($/) {
    make $/.caps[0].value.ast;
}

method enter-option($/) {
    self.enter-parent:
        my $opt = Config::BINDish::AST.new-ast('Option');
    make $opt;
}

method statement:sym<option>($/) {
    my $opt := self.inner-parent;
    $opt.add: $<option-name>.made.mark-as('option-name');
    my $val;
    with $<option-value> {
        $val = .made;
    }
    else {
        $val = Config::BINDish::AST.new-ast('Value', :payload, :type-name<bool>).mark-as('implicit');
    }
    $opt.add: $val.mark-as('option-value');
    make $opt;
}

method statement:sym<block>($/) {
    make self.inner-parent;
}

method statement:sym<empty>($/) {
    make Config::BINDish::AST.new-ast('NOP');
}

method statement:sym<include>($/) {
    make $*CFG-INC-STMTS.ast.mark-as('included');
}

method dq-string($/) {
    make Config::BINDish::AST.new-ast('Value', :payload($<string>.caps.map(*.value).join), :type-name<dq-string>);
}

method sq-string($/) {
    make Config::BINDish::AST.new-ast('Value', :payload($<string>.caps.map(*.value).join), :type-name<sq-string>);
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
    make $<keyword>.ast;
#    make Config::BINDish::AST.new-ast('Value', :payload(Str($*CFG-VALUE.payload)), :type-name<keyword>);
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
    with $<comment-body> {
        make Config::BINDish::AST.new-ast('Comment',
                                          :family<UNIX>,
                                          :body( ~$_ ));
    }
    else {
        make Config::BINDish::AST.new-ast: 'NOP'
    }
}

method keyword($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type-name<keyword>,
                                      :payload(~$<kwd>))
        .mark-as('keyword')
}

method block-class($/) {
    make $<class>.made
}

method block-name($/) {
    make $<value>.made
}

method block-head($/) {
    my $parent = self.inner-parent;
    $parent.add: $<block-type>.made.mark-as('block-type');
    with $<block-name> {
        $parent.add: .ast.mark-as('block-name');
        $parent.add: .ast.mark-as('block-class') with $<block-class>;
    }
}

method enter-block($/) {
    self.enter-parent:
        my $blk = Config::BINDish::AST.new-ast('Block');
    make $blk;
}

method block-body($/) {
    my $block = self.inner-parent;

    if $<statement-list><statements> {
        for @($<statement-list><statements>) -> $st {
            $block.add: $st.ast;
        }
    }
}

# --- Utility methods

method make-container(Config::BINDish::Grammar::Value:D $gval) {
    Config::BINDish::AST::Value($gval)
}

proto method enter-parent(| --> Config::BINDish::AST::Node:D) {*}
multi method enter-parent(Config::BINDish::AST::Node:D $inner --> Config::BINDish::AST::Node:D) {
    $*CFG-INNER-PARENT = $inner;
}
multi method enter-parent(Config::BINDish::AST::Node:U $inner, |c --> Config::BINDish::AST::Node:D) {
    $*CFG-INNER-PARENT = $inner.WHAT.new(|c)
}

method inner-parent {
    $*CFG-INNER-PARENT // fail X::NoInnerParent.new
}