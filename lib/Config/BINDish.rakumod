use v6.d;
#use Config::BINDish::Ops;
class Config::BINDish:ver($?DISTRIBUTION.meta<ver>):api($?DISTRIBUTION.meta<api>):auth($?DISTRIBUTION.meta<auth>) {
    use nqp;

    BEGIN {
        Config::BINDish.HOW does role ExtensibleHOW {
            my Mu @grammar-extensions;
            my Mu @actions-extensions;

            method extend-grammar( Mu \ext ) {
                nqp::scwbdisable();
                @grammar-extensions[+@grammar-extensions] := ext;
                nqp::scwbenable();
            }
            method extend-actions( Mu \ext ) {
                nqp::scwbdisable();
                @actions-extensions[+@actions-extensions] := ext;
                nqp::scwbenable();
            }

            method grammar-extensions {
                @grammar-extensions
            }
            method actions-extensions {
                @actions-extensions
            }
        }

        my sub add_phaser(&phaser) {
            my $unit-code-object;
            my $scopes = 0;
            while $*W.get_code_object(scopes => ++$scopes) -> \code-object {
                $unit-code-object = code-object;
            }
            $unit-code-object.add_phaser('ENTER', &phaser);
        }

        multi trait_mod:<is>( Mu:U \extension, :$BINDish-grammar! ) is export {
            add_phaser { Config::BINDish.HOW.extend-grammar: extension };
        }
        multi trait_mod:<is>( Mu:U \extension, :$BINDish-actions! ) is export {
            add_phaser { Config::BINDish.HOW.extend-actions: extension };
        }

    }

    use AttrX::Mooish;
    use Config::BINDish::Grammar;
    use Config::BINDish::Actions;

    my class ParametericCacheHOW {
        method new_type( Mu \base-type is raw ) {
            my $meta := self.new;
            my $ctype := Metamodel::Primitives.create_type( $meta, 'Uninstantiable' );
            Metamodel::Primitives.set_parameterizer( $ctype, sub ( Mu, \params ) {
                $meta.generate-grammar( base-type, params )
            } );
            $ctype
        }

        method generate-grammar( Mu \obj, @extensions ) {
            my \gmeta = obj.HOW.new;
            my $name = ( obj.^name, |@extensions.map( { '{' ~ .^name ~ '}' } ) ).join( "+" );
            my \extended = gmeta.new_type( :$name );
            extended.^set_language_version;
            for @extensions -> \ext {
                extended.^add_parent: ( ext.HOW ~~ Metamodel::ClassHOW ?? ext !! ext.^pun );
            }
            extended.^add_parent: obj;
            extended.^compose;
        }
    }

    my \grammar-cache = ParametericCacheHOW.new_type( Config::BINDish::Grammar );
    my \actions-cache = ParametericCacheHOW.new_type( Config::BINDish::Actions );

    has Config::BINDish::Grammar::Strictness:D(  ) $.strict = False;

    has Mu @.grammar-extensions;
    has Mu @.actions-extensions;
    # User-defined configuration structure. See Grammar's declare-blocks and declare-options
    has Pair:D @.blocks;
    has Pair:D @.options;
    # It makes no sense to override the grammar because it's the core of this all. Only extensions are allowed.
    has Config::BINDish::Grammar $.grammar is mooish( :lazy, :clearer ) is built( False );
    has Config::BINDish::Actions $.actions is mooish( :lazy, :clearer );
    # Source file
    has IO::Path $.file;

    # Flatten config by default if True
    has Bool:D $.flat = False;

    has $.top handles <get>;
    has $.match;

    submethod TWEAK( *%p ) {
        if %p<extend-grammar>:exists {
            self.extend-grammar: |%p<extend-grammar>
        }
        if %p<extend-actions>:exists {
            self.extend-actions: |%p<extend-actions>
        }
    }

    method extend-grammar( +@ext ) {
        @!grammar-extensions.append: @ext;
        self.clear-grammar;
        self
    }

    method extend-actions( +@ext ) {
        @!actions-extensions.append: @ext;
        self.clear-actions;
        self
    }

    method build-grammar is raw {
        # Reverse makes extensions declared later to override those declared earlier. In MRO the first in the order
        # is the first invoked.
        Metamodel::Primitives.parameterize_type: grammar-cache,
                                                 |@!grammar-extensions.reverse,
                                                 |::?CLASS.HOW.grammar-extensions.reverse;
    }

    method build-actions is raw {
        Metamodel::Primitives.parameterize_type: actions-cache,
                                                 |@!actions-extensions.reverse,
                                                 |::?CLASS.HOW.actions-extensions.reverse;
    }

    proto method read( | ) {
        LEAVE { $!top = $!match.made if $!match && $!match.made };
        $!match = {*}
    }
    multi method read( ::?CLASS:U: |c ) {
        self.new.read: |c
    }
    multi method read( ::?CLASS:D: IO:D( Str:D ) :$!file, |c ) {
        $.grammar.parse: $!file.slurp,
                         :$!file,
                         :$.actions,
                         :$!strict,
                         :$!flat,
                         :@!blocks,
                         :@!options,
                         |c
    }
    multi method read( ::?CLASS:D: Str:D :$string, |c ) {
        $.grammar.parse: $string,
                         :$.actions,
                         :$!strict,
                         :$!flat,
                         :@!blocks,
                         :@!options,
                         |c
    }

    our sub META6 { $?DISTRIBUTION.meta }
}

my proto exports-by-opt($) {*}
multi exports-by-opt($opt where "op" | "ascii-op") {
    require ::("Config::BINDish::Ops");
    ::("Config::BINDish::Ops::EXPORT::{$opt}").WHO.pairs
}
multi exports-by-opt($opt) {
    die "Unknown Config::BINDish export option '$opt'";
}

multi EXPORT(*@ns) {
    my @exports = Config::BINDish::EXPORT::DEFAULT::.pairs;
    @exports.append: exports-by-opt($_) for @ns;
    Map.new: |@exports
}
