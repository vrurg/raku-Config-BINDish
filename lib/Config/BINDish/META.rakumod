unit module Config::BINDish::META;
use META6;
use Config::BINDish;

our sub META6 {
    name           => 'Config::BINDish',
    version        => Config::BINDish.^ver,
    api            => Config::BINDish.^api,
    description    => 'Flexible BIND-like Configuration Files Support',
    raku-version   => Version.new('6.d'),
    depends        => [
        'IP::Addr',
    ],
    # test-depends   => <Test::META>,
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
        'Config::BINDish::Grammar' => 'lib/Config/BINDish/Grammar.rakumod',
        'Config::BINDish::META' => 'lib/Config/BINDish/META.rakumod',
    },
    license        => 'Artistic-2.0',
    production     => False,
}