# NAME

`Config::BINDish::Ops` - operators for [`Config::BINDish`](../BINDish.md)

# SYNOPSIS

``` 
my $cfg = Config::BINDish.new;
$cfg.read: string => q:to/CFG/;
                        top-opt "is top";
                        cluster "generic" {
                            the-answer 42;
                            group {
                                service "api" {
                                    host "h1" {
                                        ip "192.168.1.2";
                                    }
                                    host "h2" {
                                        ip "192.168.1.3";
                                        interface "eth2";
                                    }
                                }
                            }
                        }
say $cfg ∷ :cluster<generic> ∷ :group ∷ :service<api> ∷ :host<h2> ∷ <interface ip>; # eth2 192.168.1.3
say $cfg.top ∷ :cluster<generic> ∷ :group ∷ :service<api> ∷ :host<h2> ∷ <interface ip>; # eth2 192.168.1.3
```

# DESCRIPTION

## Request Operator `∷`

Request operator is a front-end to [`Config::BINDish::AST::Block`](AST/Block.md) `get` method. It is available in either Unicode (`∷`) or ASCI (`::`) form. Both are totally identical. But since the ASCI form also serves as name space separator for long names like `Config::BINDish::Ops`, there is a slight chance that it would clash that. For this reason the Unicode version is preferable.

The operator has `list` associativity making it follow any rules that apply to [the comma operator](https://docs.raku.org/routine/,).

To import any form of the operator into your code namespace, use [`Config::BINDish`](../BINDish.md) with either of both arguments:

``` 
use Config::BINDish <op>; # Import Unicode version
use Config::BINDish <ascii-op>; # Import ASCII version
use Config::BINDish <op ascii-op>; # Import both versions
```

### Syntax And Semantics

The operator mimics Raku's long name resolution behaviors. I.e. the meaning of:

``` 
$cfg ∷ :outer ∷ :inner<named> ∷ "option";
```

is to:

  - find block *outer* in the config top-level

  - then find subblock *inner* with name *"named"* in the *outer* block

  - then find *option* in the *inner* block and return its value.

Elements of the path defined with the operator can be either [`Pair`](https://docs.raku.org/type/Pair)s or strings when referring to a block. Or they could be either a string, or a list or any other [`Positional`](https://docs.raku.org/type/Positional) object which contains a list of string,when referring an option.

In a multi-component path all elements between the first and the last ones are always treated as block references.

The first element must be either an [`Config::BINDish`](../BINDish.md) instance, or a [`Config::BINDish::AST::Block`](AST/Block.md).

The last path element defines the kind of request. If it is a string, or a [`Positional`](https://docs.raku.org/type/Positional), or a [`Code`](https://docs.raku.org/type/Code) then the operator is expected to return an option. If the last element is a [`Pair`](https://docs.raku.org/type/Pair) then it is expected to return a block.

The following examples are based on the [SYNOPSIS](#SYNOPSIS) example:

``` 
$cfg ∷ :cluster<generic> ∷ :group;        # returns a block object
$cfg ∷ :cluster<generic> ∷ "the-answer";  # returns 42
$cfg ∷ :cluster<generic> ∷ :group ∷ :service<api> ∷ :host<h2> ∷ <interface ip>; # ("eth2", "192.168.1.3")
$cfg ∷ :cluster<generic> ∷ :group ∷ :service<api> ∷ :host<h2> ∷ { <interface ip> }; # ("eth2", "192.168.1.3")
```

In the last example the code block is supplied with `:host<h2>` block object as its argument. The return value of the block is turned into a [`List`](https://docs.raku.org/type/List) to be used as a positional. It means, for example, that:

``` 
$cfg ∷ :cluster<generic> ∷ { "the-answer" }
```

will return a list with a single element being `42` integer.

The operator can be adverbed with [`Config::BINDish::AST::Block`](AST/Block.md) method `get` named parameters:

``` 
$cfg ∷ :cluster<generic> ∷ <the-answer> :raw; # returns an option object
$cfg :: :cluster<generic> ∷ <group> :block;   # returns a block object
```

Also, because of the operator reliance upon the `get` method, it can return default values for elements missing from the configuration file.

# SEE ALSO

[`Config::BINDish`](../BINDish.md), \[`Config::BINDish::AST`\](rakudoc:C
