v6.d;
use Config::BINDish::Grammar;
use Config::BINDish::X;

role Config::BINDish::AST::Parent {...};
class Config::BINDish::AST::Block {...}
class Config::BINDish::AST::Option {...}
class Config::BINDish::AST::Value {...}

class Config::BINDish::AST {
    has Config::BINDish::AST::Parent $.parent;

    submethod TWEAK {
        # Record the innermost node we belong to.
        $!parent //=  $_ with $*CFG-INNER-PARENT;
    }

    my %ast-types;

    method gist {!!!}

    method set-parent( ::?CLASS:D: Config::BINDish::AST::Parent $!parent) { self }

    method ast-name(::?CLASS:D:) {
        my $name = self.^name;
        return $name unless $name.starts-with(::?CLASS.^name);
        $name.substr(::?CLASS.^name.chars + 2)
    }

    method dump(::?CLASS:D: Int:D :$level = 0) {
        say (self.ast-name ~ ": " ~ self.gist).indent($level * 4);
    }

    method register-type(Str:D $type-name, Mu \ast-type) {
        %ast-types{$type-name} := ast-type;
    }

    method new-ast(Str:D $node-type, |c --> Config::BINDish::AST:D) {
        %ast-types{$node-type}:exists
            ?? %ast-types{$node-type}.new(|c)
            !! (Config::BINDish::AST::{$node-type}:exists
                ?? Config::BINDish::AST::{$node-type}.new(|c)
                !! fail Config::BINDish::X::AST::DoestExists.new(:$node-type))
    }

    method top-node(::?CLASS:D: --> ::?CLASS) {
        return $_ with $*CFG-TOP;
        my $top = self;
        while $top.parent.defined {
            $top = $top.parent;
        }
        $top;
    }
}

role Config::BINDish::AST::Container {
    has Mu    $.payload   is built(:bind)
                          handles @Config::BINDish::Grammar::coercers
                          is default(Any);
    has Str:D $.type-name = $*CFG-VALUE ?? $*CFG-VALUE.type-name !! 'any';

    method !SET-FROM-CONTAINER(::?ROLE:D: ::?ROLE $cont) {
        with $cont {
            $!payload := .payload<>;
            $!type-name = .type-name;
        }
        else {
            $!payload = Nil;
            $!type-name = Nil;
        }
    }

    method !SET-FROM-PROFILE(::?ROLE:D: *%profile) {
        $!payload := %profile<payload><> if %profile<payload>:exists;
        $!type-name = %profile<type-name> if %profile<type-name>:exists;
    }

    method node-name { self.^shortname }

    multi method COERCE(Config::BINDish::Grammar::Value:D $val --> ::?ROLE:D) {
        self.new-ast: self.node-name,
                      payload => .coerced,
                      type-name => .type-name
                      with $val
    }
    multi method COERCE(Any:D $payload --> ::?ROLE:D) {
        my $type-name = $payload ~~ Stringy ?? 'sq-string' !! $payload.^name.lc;
        self.new-ast: self.node-name, :$payload, :$type-name
    }

    multi method ACCEPTS(::?ROLE:D $val) {
        $val.payload ~~ $!payload
    }
    multi method ACCEPTS(Any:D $val) {
        $val ~~ $!payload
    }

    method gist(::?CLASS:D: Bool :$detailed) {
        my $q = $!payload ~~ Stringy && $!type-name ne 'keyword'
            ?? ($!type-name eq 'dq-string'
                ?? '"'
                !! "'")
            !! "";
        my $str = $q ~ $!payload.gist ~ $q;
        ($detailed ?? "[" ~ $!type-name ~ " of " ~ $!payload.^name ~ "] " !! "") ~ $str
    }
}

BEGIN {
    # A temporary workaround until https://github.com/rakudo/rakudo/pull/4303 is merged. Then this piece would need
    # to be wrapped into Rakudo version check condition.
    my $payload-att = Config::BINDish::AST::Container.^candidates[0].^get_attribute_for_usage('$!payload');
    $payload-att does role {
        method add_delegator_method(Mu $pkg, $meth_name, $) {
            unless $pkg.^declares_method($meth_name) {
                nextsame;
            }
        }
    }
}

role Config::BINDish::AST::Decl {
    has Config::BINDish::AST::Container:D $.keyword is required;
}

class Config::BINDish::AST::NOP is Config::BINDish::AST {
    method gist(::?CLASS:D: ) {'*nop*'}
}

role Config::BINDish::AST::Parent {
    has Config::BINDish::AST:D @.children;

    method dump(::?CLASS:D: Int:D :$level = 0) {
        callsame;
        for @!children -> $child {
            $child.dump(:level($level+1));
        }
    }

    proto method add(::?CLASS:D: Config::BINDish::AST:D $) {*}
    multi method add(::?CLASS:D: Config::BINDish::AST:D $child --> Config::BINDish::AST:D) {
        @!children.push: $child;
        $child.set-parent(self)
    }
    multi method add(::?CLASS:D: Str:D $node-type, |c --> Config::BINDish::AST:D) {
        self.add: Config::BINDish::AST.new-ast: $node-type, |c;
    }

    proto method find-all(::?CLASS:D: |) {*}
    multi method find-all(&matcher, Bool :$local --> Seq:D) {
        lazy gather {
            my sub iterate(@children) {
                for @children -> $child {
                    take $child if &matcher( $child );
                    if !$local && $child ~~ ::?ROLE {
                        iterate $child.children;
                    }
                }
            }
            iterate @!children;
        }
    }
    multi method find-all(::?CLASS:D: :$block!, :$name, :$class, Bool :$local --> Seq:D) {
        self.find-all: -> $ast {
            $ast.^isa(Config::BINDish::AST::Block)
            && ($ast.keyword ~~ $block)
            && ( !($name.defined || $ast.name.defined) || ($name.defined && $ast.name ~~ $name) )
            && ( !($class.defined || $ast.class.defined) || ($class.defined && $ast.class ~~ $class) )
        }, :$local
    }
    multi method find-all(::?CLASS:D: :$option!, Bool :$local --> Seq:D) {
        self.find-all: {
                       .^isa(Config::BINDish::AST::Option)
                       && .keyword ~~ $option
                   }, :$local
    }

    my proto sub ensure-single(|) {*}
    multi ensure-single(@b, :$block!, *%p) {
        given +@b {
            when 1 { @b.head }
            when 0 { Nil }
            default {
                Config::BINDish::X::Block::Ambiguous.new(type => $block, :count($_), |%p).throw
            }
        }
    }
    multi ensure-single(@b, :$option!) {
        given +@b {
            when 1 { @b.head }
            when 0 { Nil }
            default {
                Config::BINDish::X::Option::Ambiguous.new(name => $option, :count($_)).throw
            }
        }
    }

    proto method find(::?CLASS:D: |) {*}
    multi method find(::?CLASS:D: :$block!, :$name, :$class, Bool :$local --> Config::BINDish::AST::Block) {
        ensure-single
            self.find-all(:$block, :$name, :$class, :$local).eager,
            :$block, :$name, :$class
    }
    multi method find(::?CLASS:D: :$option!, Bool :$local --> Config::BINDish::AST::Option) {
        ensure-single
            self.find-all(:$option, :$local).eager,
            :$option
    }

    method block(::?CLASS:D: $block, *%p) {
        self.find(:$block, |%p)
    }

    method blocks(::?CLASS:D: $block, *%p --> Seq:D) {
        self.find-all: :$block, |%p
    }

    method option(::?CLASS:D: $option, Bool :$local = True, *%p) {
        self.find(:$option, :$local, |%p)
    }

    method options(::?CLASS:D: $option, Bool :$local = True, *%p) {
        self.find-all: :$option, :$local, |%p
    }

    method value(::?CLASS:D: $option, Bool :$local = True, *%p) {
        with self.find(:$option, :$local, |%p) {
            return .value.payload
        }
        Nil
    }

    method values(::?CLASS:D: Bool :$raw) {
        self.find-all({ .^isa(Config::BINDish::AST::Value) })
            .map: { $raw ?? $_ !! .payload }
    }

    proto method get(::?CLASS:D: |) {*}
    multi method get(::?CLASS:D: Str:D $option, Bool :$raw, Bool :$local = True) {
        $raw ?? self.option($option, :$local) !! self.value($option, :$local)
    }
    multi method get(::?CLASS:D: Str:D :$option, Bool :$local = True) {
        self.option($option, :$local)
    }
    multi method get(::?CLASS:D: Str:D :$value, Bool :$local = True) {
        self.value($value, :$local)
    }
    multi method get(::?CLASS:D: Str:D :$block, *%c) {
        self.block($block, |%c)
    }
    multi method get(::CLASS:D: Pair:D $path where $path.value ~~ Pair:D | Str:D) {
        my proto traverse(Config::BINDish::AST::Block:D, |) {*}
        multi traverse(Config::BINDish::AST::Block:D $blk, Str:D $option, *%p) {
            $blk.value: $option, |%p
        }
        multi traverse(Config::BINDish::AST::Block:D $blk, Str:D :$block) {
            $blk.block: $block;
        }
        multi traverse(Config::BINDish::AST::Block:D $blk,
                       Pair:D :$block (:key($btype), :value( ($name, $class?) ) ) where $block.value ~~ Positional)
        {
            $blk.block: $btype, :$name, |(:$class with $class)
        }
        multi traverse(Config::BINDish::AST::Block:D $blk,
                       Pair:D :$block (:key($btype), :value($name)))
        {
            # Don't pass True as :name if block in the search path defined as :block-type
            $blk.block: $btype, |(:$name unless $name.^isa: Bool)
        }
        multi traverse(Config::BINDish::AST::Block:D $blk,
                       Pair:D $path (:key($block), :value($subpath)) where $path.value ~~ Pair:D | Str:D)
        {
            my $subblk = traverse($blk, :$block);
            return Nil without $subblk;
            traverse($subblk, $subpath)
        }

        traverse(self, $path)
    }
}

class Config::BINDish::AST::Value does Config::BINDish::AST::Container is Config::BINDish::AST {}

class Config::BINDish::AST::Block
    is Config::BINDish::AST
    does Config::BINDish::AST::Parent
    does Config::BINDish::AST::Decl
{
    has Config::BINDish::AST::Container $.name;
    has Config::BINDish::AST::Container $.class;
    # Whether block should merge/overwrite duplicate entries or keep them apart.
    has Bool:D $.flat = $*CFG-FLAT-BLOCKS // False;

    method set-name(::?CLASS:D: Config::BINDish::AST::Container:D $!name --> ::?CLASS:D) {
        $!name.set-parent(self);
        self
    }
    method set-class(::?CLASS:D: Config::BINDish::AST::Container:D $!class --> ::?CLASS:D) {
        $!class.set-parent(self);
        self
    }

    method gist(::?CLASS:D:) {
        $.keyword.payload
        ~ ($.name.defined
            ?? " " ~ $.name.gist
                ~ ($.class.defined ?? " " ~ $.class.gist !! "")
            !! "")
    }

    multi method add(::?CLASS:D: Config::BINDish::AST::Block:D $block) {
        nextsame unless $!flat;
        my %p;
        %p<name> = ~$_ with $block.name;
        %p<class> = ~$_ with $block.class;
        my $existing = self.block(~$block.keyword, |%p, :local);
        if $existing {
            for $block.children -> $child {
                $existing.add: $child
            }
            return $existing
        }
        nextsame
    }
    multi method add(::?CLASS:D: Config::BINDish::AST::Option:D $option) {
        nextsame unless $!flat;
        for @.children -> \child {
            if child.^isa(Config::BINDish::AST::Option)
                && child.keyword ~~ $option.keyword
            {
                return child = $option;
            }
        }
        nextsame;
    }

    method flatten(::?CLASS:D: --> ::?CLASS:D) {
        my $cloned = self.clone(:children([]), :flat);
        # Re-add children under flattening rule.
        for @.children -> $child {
            $cloned.add: $child ~~ ::?CLASS
                ?? $child.flatten
                !! $child.clone;
        }
        $cloned
    }
}

class Config::BINDish::AST::TOP
    is Config::BINDish::AST::Block
{
    method new(*%c) {
        nextwith keyword => self.new-ast('Value', :payload('*TOP*'), :type-name<keyword>), |%c
    }
    method gist(::?CLASS:D:) { "*TOP*" }
}

class Config::BINDish::AST::Option
    is Config::BINDish::AST
    does Config::BINDish::AST::Decl
{
    has Config::BINDish::AST::Container:D $.value is required;

    method gist(::?CLASS:D:) {
        $!keyword.gist ~ " " ~ $!value.gist(:detailed) ~ ";"
    }
}

class Config::BINDish::AST::Comment is Config::BINDish::AST {
    has Str:D $.family is required;
    has Str:D $.body is required;
    method gist {
        "comment[$!family] " ~ $!body.gist;
    }
}