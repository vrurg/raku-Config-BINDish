VERSIONS
========

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

