use v6.d;
class Config::BINDish::X is Exception is export {
}

role Config::BINDish::X::Parse is Config::BINDish::X {
    has Match:D $.cursor is required;
    has $.file;
    has Int $.line;

    submethod TWEAK {
        $!file = $!cursor.file;
        $!line = $!cursor.line;
    }

    method wrap-message($msg) {
        my $pre = $!cursor.prematch.split(/\n/).tail // "";
        my $post = ($!cursor.postmatch.split(/\n/).head // "").chomp;
        my $source = "";
        $source = "file " ~ $_ ~ " " with $!file;

        "===SORRY!=== Error while parsing configuration\n"
        ~ $msg ~ "\n"
        ~ ($source ~ "at line " ~ $!line).indent(2)
        ~ "\n" ~ $pre ~ "⏏" ~ $post ~ "\n"
    }
}

role Config::BINDish::X::Contextish {
    has Str:D $.what is required;
    has $.keyword is required;
    has Any:D $.ctx is required;
}

class Config::BINDish::X::Parse::General does Config::BINDish::X::Parse {
    has Str:D $.msg is required;

    method message {
        self.wrap-message($!msg);
    }
}

class Config::BINDish::X::Parse::BadNum does Config::BINDish::X::Parse {
    method message {
        self.wrap-message: "Bad number"
    }
}

class Config::BINDish::X::Parse::Context
    does Config::BINDish::X::Parse
    does Config::BINDish::X::Contextish
{
    method message {
        self.wrap-message: $.what.tc ~ " " ~ $.keyword.gist ~ " cannot be used in " ~ $.ctx.description;
    }
}

class Config::BINDish::X::Parse::Unknown does Config::BINDish::X::Parse {
    has Str:D $.what is required;
    has $.keyword is required;
    method message {
        self.wrap-message: "Unknown " ~ $.what ~ " " ~ $.keyword.gist
    }
}

class Config::BINDish::X::Parse::MissingPart does Config::BINDish::X::Parse {
    has Str:D $.what is required;
    has Str:D $.block-spec is required;
    method message {
        self.wrap-message: $.what.tc ~ " is missing in declaration of block '" ~ $!block-spec ~ "'"
    }
}

class Config::BINDish::X::Parse::ExtraPart does Config::BINDish::X::Parse {
    has Str:D $.what is required;
    has Str:D $.block-spec is required;
    method message {
        self.wrap-message: $.what.tc ~ " is unexpected in declaration of block '" ~ $.block-spec ~ "'"
    }
}

class Config::BINDish::X::Parse::Value
    does Config::BINDish::X::Parse
    does Config::BINDish::X::Contextish
{
    has $.value is required;
    method message {
        my $context = $.what.tc ~ " " ~ $.keyword.gist;
        my $props = $.ctx.props;
        my $got;
        my $why;
        if !($props.can-type-name($.value) && $props.can-type($.value)) {
            $got = $.value.type-as-str
        }
        else {
            $got = $.value.gist;
            $why = $props.why;
        }
        self.wrap-message:
            $context
                ~ " expects a " ~ $props.type-as-str
                ~ " value"
                ~ |(" (" ~ $_ ~ ")" with $why)
                ~ " but got " ~ $got
    }
}

class Config::BINDish::X::Parse::NoValueBlock
    does Config::BINDish::X::Parse
    does Config::BINDish::X::Contextish
{
    method message {
        self.wrap-message: "A value encountered in a non-value block " ~ $.keyword.gist
    }
}

class Config::BINDish::X::Parse::SpecificValue
    does Config::BINDish::X::Parse
    does Config::BINDish::X::Contextish
{
    has Str $.guess;
    method message {
        self.wrap-message: $.what.tc
                            ~ " " ~ $.keyword.gist
                            ~ " value must be "
                            ~ $.ctx.props.value-sym.join(", or ")
                            ~ ("\n" ~ .indent(4) with $.guess)
    }
}

role Config::BINDish::X::Ambiguous[Str:D $ast-type] is Config::BINDish::X {
    has Int:D $.count is required;
    method description {...}
    method message {
        "Ambiguous search result for $ast-type "
        ~ self.description
        ~ ": found $!count instances, expected 0 or 1"
    }
}

class Config::BINDish::X::Block::Ambiguous does Config::BINDish::X::Ambiguous["block"] {
    has $.type is required;
    has $.name;
    has $.class;

    method description {
        $.type
        ~ ($!name ?? ' "' ~ $!name ~ '"' !! '')
        ~ ($!class ?? ' ' ~ $!class !! '')
    }
}

class Config::BINDish::X::Block::DoesntExists is Config::BINDish::X {
    has $.type is required;
    has $.name;
    has $.class;

    method message {
        note $!name.WHICH, " // ", $!name ~~ Stringy;
        my $name = $!name
            ?? " " ~ ($!name ~~ Stringy ?? '"' ~ $!name ~ '"' !! $!name.gist )
            !! "";
        "Block `" ~ $!type.gist
        ~ $name
        ~ ($!class ?? ", " ~ $!class.gist !! "")
        ~ "` doesn't exists"
    }
}

class Config::BINDish::X::Option::DoesntExists is Config::BINDish::X {
    has $.name is required;

    method message {
        "Option '$!name' doesn't exists" # TODO add more info about error location. Config file:line would be the best.
    }
}

class Config::BINDish::X::Option::Ambiguous does Config::BINDish::X::Ambiguous["option"] {
    has $.name is required;

    method description { "'" ~ $!name ~ "'" }
}

class Config::BINDish::X::AST::DoesntExists is Config::BINDish::X {
    has Str:D $.node-type is required;
    method message {
        "No such AST node '" ~ $!node-type ~ "'"
    }
}

class Config::BINDish::X::NoInnerParent is Config::BINDish::X {
    method message {
        "Method invoked outside of the config top context. No config parsing started yet?"
    }
}

class Config::BINDish::X::AST::DuplicateType is Config::BINDish::X {
    has Str:D $.type is required;
    method message {
        "Cannot register a duplicate of AST node type '$!type'"
    }
}

class Config::BINDish::X::Parse::ContextOverwrite is Config::BINDish::X::Parse {
    has $.ctx;
    method message {
        "Attempt to re-enter a context twice detected; current context: " ~ $.ctx.description
    }
}

class Config::BINDish::X::FileNotFound is Config::BINDish::X {
    has $.file is required;
    method message {
        "File '" ~ $!file ~ "' not found"
    }
}

class Config::BINDish::X::FileOp is Config::BINDish::X {
    has $.file is required;
    has Str:D $.op is required;
    method message {
        "Cannot " ~ $.op ~ " file " ~ $.file
    }
}

class Config::BINDish::X::StmtsAdopted {
    has $.parent is required;
    method message { "Stmts AST node cannot have a parent, adoption attempted by " ~ $!parent.gist }
}

class Config::BINDish::X::OneTooMany is Config::BINDish::X {
    has Str:D $.what is required;
    method message {
        "Too many " ~ $!what ~ " found, 0 or 1 expected"
    }
}

class Config::BINDish::X::DuplicateID is Config::BINDish::X {
    has Any:D $.props is required;
    has Str:D $.keyword is required;
    has Str:D $.what is required; # Kind of entity: block or option

    method message {
        $!what.tc ~ "s '" ~ $!keyword ~ "' and '" ~ $!props.keyword
        ~ "' are both using same ID '" ~ $!props.id ~ "'"
    }
}

class Config::BINDish::X::DuplicateKeyword is Config::BINDish::X {
    has $.keyword is required;
    has $.in is required; # a BlockProps
    has $.what is required;
    method message {
        "Another declaration of $!what '$!keyword' already exists for block '" ~ $!in.keyword ~ "'"
    }
}

class Config::BINDish::X::Get::BadPathElement is Config::BINDish::X {
    has Str:D $.what is required;
    method message {
        $!what.tc ~ " cannot be used as a block path element"
    }
}

class Config::BINDish::X::ContextType is Config::BINDish::X {
    has Str:D $.type is required;
    method message {
        "Unknown parse context type '$.type'"
    }
}

class Config::BINDish::X::ConflictingProps is Config::BINDish::X {
    has Str:D $.prop1 is required;
    has Str:D $.prop2 is required;
    has Str:D $.reason is required;
    method message {
        "Options '$.prop1' and '$.prop2' are conflicting: " ~ $.reason
    }
}