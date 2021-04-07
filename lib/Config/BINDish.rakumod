use v6.d;
unit class Config::BINDish:ver<0.0.1>:api<0.1>;

use AttrX::Mooish;
use Config::BINDish::Grammar;
use Config::BINDish::Actions;

my class ParametericCacheHOW {
    method new_type( Mu \base-type is raw ) {
        my $meta := self.new;
        my $ctype := Metamodel::Primitives.create_type($meta, 'Uninstantiable');
        Metamodel::Primitives.set_parameterizer($ctype, sub ( Mu, \params ) {
            $meta.generate_grammar(base-type, params)
        });
        $ctype
    }

    method generate_grammar( Mu \obj, @extensions ) {
        my \gmeta = obj.HOW.new;
        my $name = ( obj.^name, |@extensions.map({ '{' ~ .^name ~ '}' }) ).join("+");
        my \extended = gmeta.new_type(:$name);
        extended.^set_language_revision: 'd';
        for @extensions -> \ext {
            extended.^add_parent: ( ext.HOW ~~ Metamodel::ClassHOW ?? ext !! ext.^pun );
        }
        extended.^add_parent: obj;
        extended.^compose;
    }
}

my \grammar-cache = ParametericCacheHOW.new_type(Config::BINDish::Grammar);
my \actions-cache = ParametericCacheHOW.new_type(Config::BINDish::Actions);
our @grammar-extensions;
our @actions-extensions;

BEGIN {
    multi trait_mod:<is>( Mu:U \extension, :$BINDish-grammar! ) is export {
        @Config::BINDish::grammar-extensions.push: extension if $BINDish-grammar;
    }
    multi trait_mod:<is>( Mu:U \extension, :$BINDish-actions! ) is export {
        @Config::BINDish::actions-extensions.push: extension if $BINDish-actions;
    }
}

has Config::BINDish::Grammar::Strictness:D() $.strict = False;

has Mu @.grammar-extensions;
has Mu @.actions-extensions;
# It makes no sense to override the grammar because it's the core of this all. Only extensions are allowed.
has Config::BINDish::Grammar $.grammar is mooish( :lazy, :clearer ) is built( False );
has Config::BINDish::Actions $.actions is mooish( :lazy, :clearer );

# Flatten config by default if True
has Bool:D $.flat = False;

submethod TWEAK(*%p) {
    if %p<extend-grammar>:exists {
        self.extend-grammar: |%p<extend-grammar>
    }
    if %p<extend-actions>:exists {
        self.extend-actions: |%p<extend-actions>
    }
}

method extend-grammar(+@ext) {
    @!grammar-extensions.append: @ext;
    self.clear-grammar;
    self
}

method extend-actions(+@ext) {
    @!actions-extensions.append: @ext;
    self.clear-actions;
    self
}

method build-grammar is raw {
    # Reverse makes extensions declared late to override those declared earlier. In MRO first in the order is first invoked.
    Metamodel::Primitives.parameterize_type: grammar-cache, |@!grammar-extensions.reverse, |@grammar-extensions.reverse;
}

method build-actions is raw {
    Metamodel::Primitives.parameterize_type: actions-cache, |@!actions-extensions.reverse, |@actions-extensions.reverse;
}

proto method read( | ) {*}
multi method read(::?CLASS:U: |c) {
    self.new.read: |c
}
multi method read(::?CLASS:D: Str:D :$file, |c) {
    $.grammar.parse: $file.IO.slurp, :$.actions, :$!strict, :$!flat, |c
}
multi method read(::?CLASS:D: Str:D :$string, |c) {
    $.grammar.parse: $string, :$.actions, :$!strict, :$!flat, |c
}