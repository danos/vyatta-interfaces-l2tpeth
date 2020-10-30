#! /usr/bin/perl

#
# Copyright (c) 2019 AT&T Intellectual Property. All Rights Reserved.
# Copyright (c) 2014-2016, Brocade Communications Systems, Inc.
# All rights reserved.
#
# SPDX-License-Identifier: GPL-2.0-only
#

use strict;
use warnings;

use Getopt::Long;
use JSON qw( decode_json );

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Dataplane;

sub usage {
    print "Usage: $0 <inteface>\n";
    exit 1;
}

my @statistics = (
    { tag => 'rx_bytes',       display => 'Input   bytes' },
    { tag => 'tx_bytes',       display => 'Output  bytes' },
    { tag => 'rx_packets',     display => 'Input   packets' },
    { tag => 'tx_packets',     display => 'Output  packets' },
    { tag => 'rx_bridge',      display => 'Bridged packets', hide => 1 },
    { tag => 'rx_errors',      display => 'Receive  errors', hide => 1 },
    { tag => 'tx_errors',      display => 'Transmit errors', hide => 1 },
    { tag => 'rx_nobuffer',    display => 'Buffers exhausted', hide => 1 },
    { tag => 'rx_multicast',   display => 'Input  multicast' },
    { tag => 'tx_multicast',   display => 'Output multicast' },
    { tag => 'rx_vlan',        display => 'Input Tagged', hide => 1 },
    { tag => 'rx_bad_tci',     display => 'Incorrect tag', hide => 1 },
    { tag => 'rx_bad_address', display => 'Incorrect address', hide => 1 },
);

sub show_interface {
    my ($ifinfo, $l2tpinfo) = @_;
     
    print "\nL2tpeth interface: ", $ifinfo->{name}, "\n";

    printf "   IfIndex: %d\n", $ifinfo->{ifindex};
    printf "   Mac: %s\n", $ifinfo->{ether};

    print "   Addresses:\n";
    foreach my $addr ( @{ $ifinfo->{addresses} } ) {
        my $ip = $addr->{inet};
        if ($ip) {
            print "        inet $ip, broadcast ", $addr->{broadcast}, "\n";
        }
        elsif ( $ip = $addr->{inet6} ) {
            print "        inet6 $ip, scope ", $addr->{scope}, "\n";
        }
    }

    print "   L2TPv3: Encap ", $l2tpinfo->{flags} & 2 ? "UDP" : "IP", "\n";
    printf "      %-30s %-30s\n", "Local Address: $l2tpinfo->{local_addr}",
      "Peer Address: $l2tpinfo->{peer_addr}";
    printf "      %-30s %-30s\n",  "Local Session: $l2tpinfo->{session}",
      "Peer Session: $l2tpinfo->{peer_session}";
    printf "      %-30s %-30s\n", "Local Cookie: $l2tpinfo->{cookie}",
      "Peer Cookie: $l2tpinfo->{peer_cookie}";

    print "   Statistics:\n";
    my $ifstat = $ifinfo->{statistics};
    foreach my $st (@statistics) {
        my $count = $ifstat->{ $st->{tag} };
        next unless defined($count);
        next if ( $count eq 0 && $st->{hide} );

        printf "      %-18s: %20s\n", $st->{display}, $count;
    }

}

foreach my $sid (@ARGV) {
    my $fabric = 0;

    my $sock   = new Vyatta::Dataplane($fabric);
    unless ($sock) {
        warn "Can not connect to dataplane $fabric\n";
        next;
    }

    my $response = $sock->execute("l2tpeth -s $sid");
    next unless defined($response);

    my $decoded = decode_json($response);
    my @results_l2tp = @{ $decoded->{l2tp} };

    die "session $sid does not exist on system\n"
      if ( $#results_l2tp < 0 );

    foreach (@results_l2tp) {
	my $ifname = $_->{ifname};

	$response = $sock->execute("ifconfig $ifname");
	next unless defined($response);

	$decoded = decode_json($response);
	my @results_dp = @{ $decoded->{interfaces} };

	print "interface $ifname does not exist on system\n"
	    if ( $#results_dp < 0 );

	show_interface( $results_dp[0], $_ );
    }
}
