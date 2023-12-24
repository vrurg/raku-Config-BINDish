# NAME

`Config::BINDish::Expandable` - `Config::BINDish` extension implmeneting expandable strings

# DESCRIPTION

This module extends [`Config::BINDish`](../BINDish.md) with strings which can include other option values. Only double-quoted string (i.e. those for which [`Config::BINDish::Grammar::Value`](Grammar/Value.md) and [`Config::BINDish::AST::Value`](AST/Value.md) have type name set to *dq-string*) are expandable.

To incorporate a value into a string the following macro format is used:

``` 
'{' <option> | <option-path> | '$' <environment-variable> ['?'] '}'
```

## Option

*option* is a plain string naming an option from the current block:

``` 
server "S1" {
    name "server.local";
    description "{name} is a mock server"; # becomes "server.local is a mock server"
}
```

## Option Path

*option-path* defines a path to the option if it is located in another block. It consist of a list of blocks in the order of nesting and must end with an option name. Elements in a path are separated with a slash (`/`) symbol.

The path can be relative or absolute. Absolute paths are started with a slash:

``` 
base-url "https://localhost"
resource "Test" {
    url "{/base-url}/test";
}
```

Relative paths can use double-dot notation to refer to a parent block:

``` 
pool "shared" {
    base-url "https://base";
    resource "bar" {
        url "{../base-url}/bar"; # https://base/bar
    }
}
```

To define a block where the option is to be located the following syntax is used:

``` 
block-type[([name [, class]])]
```

For example:

``` 
resource "default" {
    url "https://localhost";
}
resource "test1" addr {
    component "foo"
}
client-data {
    url "{/resource(default)/url}/{/resource("test1", addr)/component}"; # https://localhost/foo
}
```

Referring to a nested block can be done as in the following example:

``` 
resource "default" {
    urls {
        base "https://localhost";
    }
}
client-data {
    user-profile "{/resource(default)/urls/base}/user"; # https://localhost/user
}
```

Symbol escaping is traditionally done with a backslash:

``` 
client-data {
    description "Some basic info \{?} \\";
}
```

## Environment

Environment variables are expanded with `"{$HOME}"` syntax. For example:

``` 
base-dir "{$HOME}/.myapp";
```

Normally, if requested environment variable doesn't exists the parser would throw `Config::BINDish::X::Macro::DoesntExists` exception. But if the variable name is followed with a question mark sign then the macro would be expanded into an empty string:

``` 
default-prefix "{$MYAPP_PFX?}";
table-prefix "{default-prefix}my_table";
```

## This Is A Value\!

*Actually, this is a [`Config::BINDish::AST::Container`](AST/Container.md). And a [`Config::BINDish::AST::Node`](AST/Node.md). But as long as we talk about option values, so – let it be a value then.*

Because expandable strings are normal values they can be used anywhere, where a value is accepted. We can do things like expanding a string within a macro:

``` 
default-server "A1";
server "A1" {
    url "https://a1.local";
}
server "A2" {
    url "https://a2.local";
}
network "Office" {
    api-url "{/server("{/default-server}")}/api"; # https://a1.local/api
}
```

This works because when a macro is expanded server name and class can be specified using string values.

# SEE ALSO

  - [`Config::BINDish`](../BINDish.md)

  - [`Config::BINDish::AST`](AST.md)

  - [`README`](../../../../README.md)

  - [`INDEX`](../../../../INDEX.md)

# COPYRIGHT

(c) 2023, Vadim Belman <vrurg@cpan.org>

# LICENSE

Artistic License 2.0

See the [*LICENSE*](../../../../LICENSE) file in this distribution.
