use v6.d;
unit module Config::BINDish::INET;
use Config::BINDish;
use Config::BINDish::AST;
use IP::Addr;

role Grammar is BINDish-grammar {
    token value:sym<IP> {
        <ipv4-variants> | <ipv6-variants>
    }

    token value:sym<URL> {
        \w+ '://' \w+ \S*? <?before <.statement-terminator>>
    }

    token ipv4-variants {
        <ipv4-cidr> | <ipv4>
    }

    token ipv4 {
        <ipv4-octet> ** 4 % '.'
    }

    token ipv4-octet {
        \d ** 1..3 <?{ Int($/) < 256  }>
    }

    token ipv4-cidr {
        <ipv4> '/' <ipv4-mask>
    }

    token ipv4-mask {
        <ipv4> | \d+ <?{ Int($/) <= 32 }>
    }

    token ipv6-variants {
        :my $*CFG-MAX-HEXTETS = 8;
        <ipv6-cidr> | <ipv6-scoped> | <ipv6>
    }

    token ipv6 {
        <ipv6-full>
        | <ipv6-mapped>
        | <ipv6-compressed>
    }

    token ipv6-cidr {
        <ipv6> '/' <ipv6-prefix-len>
    }

    token ipv6-scoped {
        <ipv6> '%' $<scope>=( \S+ )
    }

    token ipv6-full {
        <ipv6-hextet> ** { $*CFG-MAX-HEXTETS } % ':'
    }

    my sub hextets2int ( @hx ) {
        my $pfx = 0;
        $pfx = ( $pfx +< 16 ) +| $_ for @hx;
        $pfx
    }

    token ipv6-mapped {
        :temp $*CFG-MAX-HEXTETS = 6;
        [
        <ipv6-full> <?{
            hextets2int( $/<ipv6-full><ipv6-hextet>.map: { (~$_).parse-base( 16 ) } ) ==
            0xffff | 0xffff0000 | 0x64ff9b0000000000000000
        }> ':'
        | [
        <ipv6-compressed> <?{ (~$/).ends-with( '::' ) }> # when compressed ends with ::
        | <ipv6-compressed> ':'
        ] <?{
            my @pfx = $/<ipv6-compressed><ipv6-sub>[0]<ipv6-hextet>.map: { (~$_).parse-base(16) };
            my @sfx = $/<ipv6-compressed><ipv6-sub>[1]<ipv6-hextet>.map: { (~$_).parse-base(16) };
            my @zero = 0 xx ($*CFG-MAX-HEXTETS - @pfx.elems - @sfx.elems);
            hextets2int( (@pfx, @zero, @sfx).flat ) ==
            0xffff | 0xffff0000 | 0x64ff9b0000000000000000
        }>
        ]
        <ipv4>
    }

    token ipv6-compressed {
        <ipv6-sub> $<double-col>='::' <ipv6-sub>
        <?{ ($/<ipv6-sub>[0]<ipv6-hextet>.elems + $/<ipv6-sub>[1]<ipv6-hextet>.elems) < $*CFG-MAX-HEXTETS }>
    }

    token ipv6-sub {
        <ipv6-hextet> ** { ^($*CFG-MAX-HEXTETS - 1) } % ':'
    }

    token ipv6-hextet {
        <.xdigit> ** 1..4 <!before '.' >
    }

    token ipv6-prefix-len {
        <.digit> ** ^4 <?{ Int($/) <= 128 }>
    }
}

role Actions is BINDish-actions {
    method value:sym<IP>($/) {
        my $ip-obj = IP::Addr.new(~$/);
        my $ip-type = 'IPv' ~ $ip-obj.version;

        make Config::BINDish::AST.new-ast: 'Value',
                                           type => IP::Addr,
                                           type-name => $ip-type,
                                           payload => $ip-obj;
    }

    method value:sym<URL>($/) {
        make Config::BINDish::AST.new-ast: 'Value',
                                           type => Str,
                                           type-name => 'URL',
                                           payload => ~$/;
    }
}