use v6.d;
use Test::Async::Decl;
unit test-bundle Config::BINDish::Test;

use Test::Async::Utils;
use Config::BINDish::X;

my class StatementsDescriptor {
    # Only those to be tested. Keys are indices in $match<statements> array.
    has %.statements;
    has Int $.stmt-count;
    has Int %.plans;
    has Str $.message is rw;
    has Str $.todo;
    has Bool:D $.parallel = False;

    multi method new(Hash() $profile) {
        self.new: |$profile
    }
}

method is-struct-deeply(Match $match is raw, %struct, Str:D :$path = "") is test-tool {
    my $passed = True;
    for %struct.sort -> (:key($token), :value($matcher)) {
        my $token-path = $path ~ "<$token>";
        if $passed &&= self.ok( ?($match{$token}:exists), $token-path ~ " exists" ) {
            $passed &&= do given $matcher {
                when StatementsDescriptor {
                    self.is-cfg-stmt-list: $match{$token}, $matcher, :path($token-path);
                }
                when Associative {
                    self.is-struct-deeply: $match{$token}, %($matcher), :path($token-path);
                }
                when Code {
                    self.ok: ( $match{$token} ~~ $_ ), $token-path ~ " matches validator code";
                }
                when Regex {
                    self.ok: ( $match{$token} ~~ $_ ), $token-path ~ " matches regex";
                }
                default {
                    self.cmp-ok: ~$match{$token}, '~~', $matcher, $token-path ~ " value";
                }
            }
        }
    }
    $passed;
}

method is-cfg-stmts(Mu $match is raw, Hash() $struct, Str:D $message, Int :$plan is copy) is test-tool {
    my sub struct-plan-estimate($substruct) {
        my $est = 0;
        for $substruct.values -> $matcher {
            if $matcher ~~ Associative {
                # For associative it's :exists test + subtests for its keys
                $est += 1 + struct-plan-estimate(%($matcher));
            }
            else {
                # For a value it's :exists test and value test. Value could be a statements descriptor too which is a
                # single subtest
                $est += 2;
            }
        }
        $est
    }

    $plan //= struct-plan-estimate($struct);

    self.subtest: :hidden, $message, -> \suite {
        suite.plan: $plan;

        unless suite.is-struct-deeply: $match, $struct {
            suite.diag: $match.gist;
        }
    }
}

method is-cfg-stmt-list(Mu $match is raw,
                        StatementsDescriptor() $desc,
                        Str $message? is copy,
                        Str :$path)
    is test-tool
{
    self.todo: $_ with $desc.todo;

    $message //= $desc.message // ($path ?? "Statement list in $path" !! "<*anon*>");

    with $match {
        self.subtest: :hidden, $message, -> \suite {
            suite.plan: $desc.statements.elems + 3, :parallel($desc.parallel);

            my $max-idx = (-1, |$desc.statements.keys.map(*.Int)).max;

            suite.is-struct-deeply: $match,
                                   %( statement-list => statements => -> $m {
                                       with $desc.stmt-count {
                                           $m.elems == $_
                                       }
                                       else {
                                           $m.elems > $max-idx
                                       }
                                   } );

            my @stmts = $match<statement-list><statements>;
            for $desc.statements.sort -> (Int() :key($idx), Hash() :value($substruct)) {
                suite.is-cfg-stmts: @stmts[$idx], $substruct, "Statement $idx",
                                    |(plan => $_ with $desc.plans{$idx});
            }
        }
    }
    else {
        self.flunk: $message;
        self.diag: $match.exception.gist if $match ~~ Failure;
    }
}

method run-grammar-tests(Mu \grmr, *@tests) is test-tool(:!wrap) {
    self.anchor: {
        for @tests -> ( :key($message), :value(%struct) ) {
            my $match;
            my $ex;
            try {
                $match = grmr.parse: %struct<source>;
                CATCH {
                    default {
                        $ex = $_;
                    }
                }
            }
            with $ex {
                .rethrow unless $_ ~~ Config::BINDish::X::Parse;
                self.proclaim: False, $message, { :comments( $ex.message ), caller => self.tool-caller.frame };
                # ~ "\n" ~ $ex.message;
            }
            else {
                with %struct<top> {
                    self.is-cfg-stmt-list: $match, %struct<top>, $message;
                }
                else {
                    self.flunk: $message;
                    self.diag: "*WARNING!* No 'top' key found for '$message'!";
                }
            }
        }
    }
}

method token-statements(*%desc) is test-tool(:!wrap) {
    StatementsDescriptor.new: |%desc;
}
