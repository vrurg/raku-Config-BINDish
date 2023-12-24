# VERSIONS

  - **v0.0.18**
    
      - Fix list of registered extensions getting reset by bytecode deserialization

  - **v0.0.17**
    
      - Allow use of the same keyword for blocks and options. It only works when the keyword is used in different blocks, apparently:
        
        ``` 
        services {
            service "mail" {
                # parameters of the service
            }
        }
        client "foo" {
            # Use this service for reporting
            service "mail";
        }
        ```
    
      - Improved error reporting

  - **v0.0.15**
    
      - Fix some issues with exceptions
    
      - Set version of generated extension classes to compiler's default

  - **v0.0.14**
    
      - Fix testing on Windows platforms where there is no $HOME

  - **v0.0.13**
    
      - Make macro expansion work for option default value
    
      - Add support for environment variables in macro expansion

  - **v0.0.12**
    
      - A new `no-values` block property in pre-declarations to declare option-only blocks
    
      - Implemented value constraints via a new `where` pre-declaration property
    
      - Fixed a race condition which allowed for non-values to be parsed as values
    
      - Fixed a problem when a type cannot coerce from a `Match` object

  - **v0.0.11**
    
      - Fix `AttrX::Mooish` dependency version

  - **v0.0.10'**
    
      - Added support for classified blocks for `:in` key of block and option declarations

  - **v0.0.9**
    
      - Fix node dumping
    
      - Fix expandable strings not considered standalone values
    
      - `find-all` results sequence is not lazy anymore
    
      - Make dump output a little bit prettier

  - **v0.0.8**
    
      - Fix parsing of paths of `dir/path` kind in value only blocks
    
      - Fix a copypasto in export of ASCII version of `::` operator
    
      - Some improvements in error reporting

  - **v0.0.7**
    
      - Change some identity/value methods from returning an `AST::Container` to its value instead [b7ece317](https://github.com/vrurg/raku-Config-BINDish/commit/b7ece3173f156e94c8d42d3a12edc44cd33b8b26)
    
      - Use more legit approach in registering phasers

  - **v0.0.6**
    
    Bugfix release:
    
      - Moved `Test::Async` dependency from `test-depends` into `depends`
    
      - Fixed boolean values conflicting and racing with keywords. Booleans now have higher-priority over keywords
    
      - Fix wrong line number reported for errors pointing at a line start
    
      - Fixed `Expandable` loosing values and causing weird parsing errors

  - **v0.0.5**
    
      - Added support for default values
    
      - Multi-option queries
    
      - Request operator(s): `∷` and `::`
    
      - Clarified `.get` API
    
      - Minor technical cleanups

  - **v0.0.4**
    
      - Added support for context-dependent declarations.
    
    This is a major change in the module logic. Whereas the previous versions considered each pre-declared keyword unique per its type (i.e. per options or blocks) and per configuration, they can now be made unique per individual block. See [`Config::BINDish::Grammar`](docs/md/Config/BINDish/Grammar.md) for more information.
    
      - Added two implicitly pre-declared blocks: `.TOP` and `.ANYWHERE`
    
      - [`Config::BINDish::Grammar::StatementProps`](docs/md/Config/BINDish/Grammar/StatementProps.md) attribute `$.top-only` is deprecated; `:in<.TOP>` must be used instead of `:top-only` in a statement properties hash
    
      - [`Config::BINDish::Grammar::Strictness`](docs/md/Config/BINDish/Grammar/Strictness.md) got one more mode: `warnings`
    
      - [`Config::BINDish::INET`](docs/md/Config/BINDish/INET.md) extension now sets `$*CFG-VALUE`
    
      - Fixed some error reports
    
      - Improved handling of context leaving

  - **v0.0.3**
    
      - Implemented support for `include`, see README for more details
    
      - Implemented support for `#line` directive, see README too
    
      - Internal: replaced an explicit context stack with `$*CFG-CTX` on call stack
    
      - Methods `push-ctx` and `pop-ctx` are gone; method `enter-ctx` is introduced
    
    https://github.com/vrurg/raku-Config-BINDish/commit/b9b4fd97af431dae703e3b6d7c3afd5cfe8e195f contains detailed list of changes.

  - **v0.0.2**
    
      - Implemented grammar value type (`value:sym<type>`) specification
    
      - Replaced dot (`.`) separator with slash (`/`) in macros: `"{block.option}"` is now `"{block/option}"`
    
      - Implemented parent block reference in macros: `"{../../option}"`
    
      - Added a new standard value type: file path
    
      - API version bumped to v0.0.2

# SEE ALSO

  - [`INDEX`](INDEX.md)
