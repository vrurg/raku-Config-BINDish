unit module Config::BINDish::META;
use META6;
use Config::BINDish;

our sub META6 {
    name           => 'Config::BINDish',
    version        => Config::BINDish.^ver,
    api            => Config::BINDish.^api,
    description    => 'Extensible BIND9-like Configuration Files Support',
    raku-version   => Version.new('6.d'),
    depends        => [
        'AttrX::Mooish',
        'IP::Addr',
    ],
    test-depends   => [
        'Test::Async:auth<zef:vrurg>:ver<0.1.2+>',
    ],
    # build-depends  => <META6 p6doc Pod::To::Markdown>,
    tags           => <CONFIG>,
    authors        => ['Vadim Belman <vrurg@lflat.org>'],
    auth           => 'zef:vrurg',
    source-url     => 'https://github.com/vrurg/raku-Config-BINDish.git',
    support        => META6::Support.new(
        source          => 'https://github.com/vrurg/raku-Config-BINDish.git',
        ),
    provides => {
        'Config::BINDish' => 'lib/Config/BINDish.rakumod',
        'Config::BINDish::Actions' => 'lib/Config/BINDish/Actions.rakumod',
        'Config::BINDish::AST' => 'lib/Config/BINDish/AST.rakumod',
        'Config::BINDish::Expandable' => 'lib/Config/BINDish/Expandable.rakumod',
        'Config::BINDish::Grammar' => 'lib/Config/BINDish/Grammar.rakumod',
        'Config::BINDish::INET' => 'lib/Config/BINDish/INET.rakumod',
        'Config::BINDish::META' => 'lib/Config/BINDish/META.rakumod',
        'Config::BINDish::Ops' => 'lib/Config/BINDish/Ops.rakumod',
        'Config::BINDish::Test' => 'lib/Config/BINDish/Test.rakumod',
        'Config::BINDish::X' => 'lib/Config/BINDish/X.rakumod',
    },
    license        => 'Artistic-2.0',
    production     => True,
}