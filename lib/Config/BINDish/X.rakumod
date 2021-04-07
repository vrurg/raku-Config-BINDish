use v6.d;
class Config::BINDish::X is Exception is export {
}

class Config::BINDish::X::Parse is Config::BINDish::X {
    has Match:D $.cursor is required;
    has Str:D $.msg is required;

    method line {
        ($!cursor.prematch ~ $!cursor).chomp.split(/\n/).elems;
    }

    method message {
        my $pre = ($!cursor.prematch ~ $!cursor).chomp.split(/\n/).reverse.grep(*.chars).head;
        my $post = $!cursor.postmatch.split(/\n/).head.chomp;
        "===SORRY!=== Error while parsing configuration file\n" ~
        $!msg ~ "\n"
        ~ ("at line " ~ self.line).indent(2)
        ~ "\n" ~ $pre ~ "⏏" ~ $post ~ "\n"
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

class Config::BINDish::X::Blocl::Ambiguous does Config::BINDish::X::Ambiguous["block"] {
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
        "Block '" ~ $!type.gist
        ~ ($!name ?? " " ~ $!name.gist !! "")
        ~ ($!class ?? ", " ~ $!class.gist !! "")
        ~ "' doesn't exists"
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