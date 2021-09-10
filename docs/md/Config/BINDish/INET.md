NAME
====

`Config::BINDish::INET` - implement IP addresses as values

DESCRIPTION
===========

This module extends [`Config::BINDish`](../BINDish.md) with ability to parse IPv4/IPv6 IP addresses and networks; and with very generic form of URIs.

For supported IP formats see [`IP::Addr`](https://modules.raku.org/dist/IP::Addr) module.

URIs are basically anything starting with a word followed with `://` and then with non-whitespace symbols. For example:

    foo://buppa-duppa_dop?oki,this_thing_works!

is a valid URI.

This Is A Value!
----------------

This extension creates a normal [`Config::BINDish::AST::Value`](AST/Value.md). And as such it can be used anywhere where a value is allowed. Say, we can decalre a network block:

    network 192.168.1.0/24 {
        ns { 192.168.1.1; 192.168.1.5 }
        default-gw 192.168.1.1;
        admin-url https://router.local/login;
    }

Type names used for values produced by this extension are:

  * `IPv4`

  * `IPv6`

  * `URL`

For IP data payload is of [`IP::Addr`](https://modules.raku.org/dist/IP::Addr) type. This makes it possible for the above example to do something like this in your code:

    my $network = $cfg.top.block("network");
    for $network.name.payload.netowrk.each -> $ip {
        say $ip;
    }

Apparently, if you declare more than one `network` block in your config you'd have to be more specific in call to method `block` and use something like:

    my $network = $cfg.top.block("network", name => IP::Addr.new('192.168.1.0/24'));

Or you may want to iterate over all known networks. Then it would be:

    for $cfg.top.blocks("network") -> $network {
        ...
    }

SEE ALSO
========

[`Config::BINDish`](../BINDish.md), [`Config::BINDish::AST`](AST.md)

AUTHOR
======

Vadim Belman <vrurg@cpan.org>

