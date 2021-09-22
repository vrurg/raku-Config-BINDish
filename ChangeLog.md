VERSIONS
========

head
====

v0.0.6

Bugfix release:

  * Moved `Test::Async` dependency from `test-depends` into `depends`

  * Fixed boolean values conflicting and racing with keywords. Booleans now have higher-priority over keywords

  * Fix wrong line number reported for errors pointing at a line start

  * Fixed `Expandable` loosing values and causing weird parsing errors

head
====

v0.0.5

  * Added support for default values

  * Multi-option queries

  * Request operator(s): `∷` and `::`

  * Clarified `.get` API

  * Minor technical cleanups

v0.0.4
------

  * Added support for context-dependent declarations.

This is a major change in the module logic. Whereas the previous versions considered each pre-declared keyword unique per its type (i.e. per options or blocks) and per configuration, they can now be made unique per individual block. See [`Config::BINDish::Grammar`](docs/md/Config/BINDish/Grammar.md) for more information.

  * Added two implicitly pre-declared blocks: `.TOP` and `.ANYWHERE`

  * [`Config::BINDish::Grammar::StatementProps`](docs/md/Config/BINDish/Grammar/StatementProps.md) attribute `$.top-only` is deprecated; `:in<.TOP>` must be used instead of `:top-only` in a statement properties hash

  * [`Config::BINDish::Grammar::Strictness`](docs/md/Config/BINDish/Grammar/Strictness.md) got one more mode: `warnings`

  * [`Config::BINDish::INET`](docs/md/Config/BINDish/INET.md) extension now sets `$*CFG-VALUE`

  * Fixed some error reports

  * Improved handling of context leaving

v0.0.3
------

  * Implemented support for `include`, see README for more details

  * Implemented support for `#line` directive, see README too

  * Internal: replaced an explicit context stack with `$*CFG-CTX` on call stack

  * Methods `push-ctx` and `pop-ctx` are gone; method `enter-ctx` is introduced

https://github.com/vrurg/raku-Config-BINDish/commit/b9b4fd97af431dae703e3b6d7c3afd5cfe8e195f contains detailed list of changes.

v0.0.2
------

  * Implemented grammar value type (`value:sym<type>`) specification

  * Replaced dot (`.`) separator with slash (`/`) in macros: `"{block.option}"` is now `"{block/option}"`

  * Implemented parent block reference in macros: `"{../../option}"`

  * Added a new standard value type: file path

  * API version bumped to v0.0.2

