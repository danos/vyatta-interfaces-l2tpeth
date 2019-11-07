#! /usr/bin/perl

#
# Copyright (c) 2019 AT&T Intellectual Property. All Rights Reserved.
# Copyright (c) 2014-2016, Brocade Communications Systems, Inc.
# 
# SPDX-License-Identifier: GPL-2.0-only
#

use strict;
use warnings;

use lib "/opt/vyatta/share/perl5/";
use Vyatta::Address;
use Vyatta::Interface;
use Vyatta::Config;

my ($action, $ifname) = @ARGV;

# Register the interface to be managed with ifmgrd
system("ifmgrctl register $ifname") == 0
 or exit 1;

# Get bridge information from configuration
my $intf = new Vyatta::Interface($ifname);

my $cfg = new Vyatta::Config($intf->path());

my $encap = $cfg->returnValue('l2tp-session encapsulation');
my $tunnel = $cfg->returnValue('l2tp-session local-session-id');
my $peer_tunnel = $cfg->returnValue('l2tp-session remote-session-id');
my $session = $cfg->returnValue('l2tp-session local-session-id');
my $old_session = $cfg->returnOrigValue('l2tp-session local-session-id');
my $peer_session = $cfg->returnValue('l2tp-session remote-session-id');
my $local_ip = $cfg->returnValue('l2tp-session local-ip');
my $peer_ip = $cfg->returnValue('l2tp-session remote-ip');
my $local_cookie = $cfg->returnValue('l2tp-session local-cookie');
my $peer_cookie = $cfg->returnValue('l2tp-session remote-cookie');
my $local_udp = $cfg->returnValue('l2tp-session local-udp-port');
my $peer_udp = $cfg->returnValue('l2tp-session remote-udp-port');
my $port = " ";
my $cookie = " ";

$port = "udp_sport $local_udp udp_dport $peer_udp"
    if defined($local_udp);
$cookie = "cookie $local_cookie peer_cookie $peer_cookie"
    if defined($local_cookie and $peer_cookie);

if ( $action eq 'SET' ) {
    unless ( defined($tunnel)
        and defined($peer_tunnel)
        and defined($encap)
        and defined($local_ip)
        and defined($peer_ip)
        and defined($session)
        and defined($peer_session)) {
        # configd:defer-actions might calls this with $action SET
        # even if the CLI is not yet completed and by-passes verification of
        # lt2tp-session leaf-node.
        # In that case, gracefully stop here.
        exit 0;
    }
    add_new_session($tunnel, $peer_tunnel, $encap, $local_ip, $peer_ip, 
		    $port, $session, $peer_session, $cookie, $ifname);
} elsif ( $action eq 'DELETE' ) {
    delete_tun_session($old_session);
} elsif ( $action eq 'ACTIVE' ) {
    if ( $cfg->getNodeStatus('l2tp-session') eq 'deleted' ) {
        # configd:defer-actions might calls this with $action ACTIVE
        # even if the l2tp interface got just deleted.
        # In that case, gracefully stop here.
        exit 0;
    }

    if ( defined($old_session) ) {
	my $old_remote_ip = $cfg->returnOrigValue('l2tp-session remote-ip');
	my $old_encap = $cfg->returnOrigValue('l2tp-session encapsulation');
	my $old_tunnel = $cfg->returnOrigValue('l2tp-session local-session-id');
	my $old_peer_tunnel = $cfg->returnOrigValue('l2tp-session remote-session-id');
	my $old_peer_session = $cfg->returnOrigValue('l2tp-session remote-session-id');
	my $old_local_ip = $cfg->returnOrigValue('l2tp-session local-ip');
	my $old_local_cookie = $cfg->returnOrigValue('l2tp-session local-cookie');
	my $old_peer_cookie = $cfg->returnOrigValue('l2tp-session remote-cookie');
	my $old_local_udp = $cfg->returnOrigValue('l2tp-session local-udp-port');
	my $old_peer_udp = $cfg->returnOrigValue('l2tp-session remote-udp-port');

	my $old_cookie = " ";
	my $old_port = " ";

	$old_port = "udp_sport $old_local_udp udp_dport $old_peer_udp"
	    if defined($old_local_udp);	
	$old_cookie = "cookie $old_local_cookie peer_cookie $old_peer_cookie"
	    if defined($old_local_cookie and $old_peer_cookie);

	# Delete and recreate the tunnel only if the l2tp-session parameters change.
	# If those are unchanged, do nothing and let the commit algorithm apply
	# rest of the changed config under l2tpeth.
	if ( ($tunnel ne $old_tunnel) or ($peer_tunnel ne $old_peer_tunnel) or
	     ($session ne $old_session) or ($peer_session ne $old_peer_session) or
	     ($local_ip ne $old_local_ip) or ($peer_ip ne $old_remote_ip) or 
	     ($port ne $old_port) or ($cookie ne $old_cookie) or 
	     ($encap ne $old_encap) ) {
		delete_tun_session($old_session);
		add_new_session($tunnel, $peer_tunnel, $encap, $local_ip, $peer_ip,
                    $port, $session, $peer_session, $cookie, $ifname);
	}
    }
}

exit 0;

sub delete_tun_session {
    my $old_session = shift;
    system("ip l2tp del session tunnel_id $old_session session_id $old_session") == 0
	or exit 1;
    system("ip l2tp del tunnel tunnel_id $old_session") == 0
	or exit 1;
}

sub add_new_session {
    my ($tunnel, $peer_tunnel, $encap, $local_ip, $peer_ip, $port, $session, $peer_session, $cookie, $ifname) = @_;

    # For IPv4 & IPv6, the local address must be on an interface that is up
    my ( $if_name, $link_up, $ip_tentative ) =
      Vyatta::Address::get_interface($local_ip);
    die "Error: Local address $local_ip must exist before adding tunnel\n"
      unless $$if_name;
    die "Error: Interface $$if_name must be up before adding tunnel\n"
      unless $$link_up;

    # For IPv6 delay adding tunnel until local address is assigned
    if ( Vyatta::Address::is_ipv6($local_ip) ) {
        Vyatta::Address::ipv6_tentative_addr_dad_wait( $$if_name, $local_ip );
    }

    system("ip l2tp add tunnel tunnel_id $tunnel peer_tunnel_id $peer_tunnel encap $encap local $local_ip remote $peer_ip $port") == 0
	or exit 1;

    system("ip l2tp add session tunnel_id $tunnel session_id $session peer_session_id $peer_session $cookie name $ifname l2spec_type none") == 0
	or exit 1;

}
