use v6.d;
unit module Config::BINDish::Ops;
use Config::BINDish::AST;
use Config::BINDish::Grammar;
use Config::BINDish;

proto RESOLVE-PATH(Config::BINDish::AST::Block:D, +@, |) {*}
multi RESOLVE-PATH(Config::BINDish::AST::Block:D $blk, @path where *.tail ~~ Str:D, *%c)
{
    $blk.get: @path, :!block, |%c
}
multi RESOLVE-PATH(Config::BINDish::AST::Block:D $blk, @path, *%c) {
    # Enforce request for a block if the last path element is a Pair.
    my $block = @path.tail ~~ Pair:D;
    $blk.get: @path, :$block, |%c
}

proto infix:<∷>(|) is export(:op) is assoc<list> {*}
multi infix:<∷>(Config::BINDish::AST::Block:D $blk, +@path, |c) {
    RESOLVE-PATH($blk, @path, |c)
}
multi infix:<∷>(Config::BINDish:D $cfg, +@path, |c) {
    RESOLVE-PATH($cfg.top, @path, |c)
}

proto infix:<::>(|) is export(:op) is assoc<list> {*}
multi infix:<::>(Config::BINDish::AST::Block:D $blk, +@path, |c) {
    RESOLVE-PATH($blk, @path, |c)
}
multi infix:<::>(Config::BINDish:D $cfg, +@path, |c) {
    RESOLVE-PATH($cfg.top, @path, |c)
}
