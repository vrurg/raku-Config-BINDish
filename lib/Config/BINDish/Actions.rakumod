use v6.d;
unit class Config::BINDish::Actions;

use Config::BINDish::AST;
use Config::BINDish::X;

has Bool:D $.flat = False;

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
    make Config::BINDish::AST.new-ast('Value',
                                      :type(Str),
                                      :type-name<dq-string>,
                                      :payload($<string>.chunks.map(*.value).join));
}

method sq-string($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type(Str),
                                      :type-name<sq-string>,
                                      :payload($<string>.chunks.map(*.value).join));
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

method value:sym<int>($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type(Int),
                                      :type-name<int>,
                                      :payload($/.Int));
}

method value:sym<bool>($/) {
    make $<bool-val>.made
}

method bool-true($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type(Bool),
                                      :type-name<bool>,
                                      :payload)
}

method bool-false($/) {
    make Config::BINDish::AST.new-ast('Value',
                                      :type(Bool),
                                      :type-name<bool>,
                                      :!payload);
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
                                      :type(Str),
                                      :type-name<keyword>,
                                      :payload(~$/))
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