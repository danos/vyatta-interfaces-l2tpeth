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
use Vyatta::Interface;
use Vyatta::Config;
use Vyatta::VPlaned;

use vyatta::proto::XConnectConfig;

die "$#ARGV Usage: $0 action dp_ifname\n" unless ($#ARGV == 1);

my ($action, $ifname) = @ARGV;

my $intf = new Vyatta::Interface($ifname);
my $cfg = new Vyatta::Config($intf->path());
my $l2tpifname = $cfg->returnValue('xconnect l2tpeth');
my $oldl2tpifname = $cfg->returnOrigValue('xconnect l2tpeth');
my $xconn_ttl = $cfg->returnValue('xconnect ttl');
my $vhostifname = $cfg->returnValue('xconnect vhost');
my $oldvhostifname = $cfg->returnOrigValue('xconnect vhost');
my $dp_ifname = $cfg->returnValue('xconnect dataplane');
my $olddp_ifname = $cfg->returnOrigValue('xconnect dataplane');

my $peer_ifname = $l2tpifname if (defined($l2tpifname));
$peer_ifname = $vhostifname if (defined($vhostifname));
$peer_ifname = $dp_ifname if (defined($dp_ifname));
my $old_peer_ifname = $oldl2tpifname if (defined($oldl2tpifname));
$old_peer_ifname = $oldvhostifname if (defined($oldvhostifname));
$old_peer_ifname = $olddp_ifname if (defined($olddp_ifname));

XConnectConfig::CommandType->import(":constants");

if ( $action eq 'SET' ) {
    if ( defined($l2tpifname) ) {
	set_xconnect_port_l2tpeth("add", $ifname, $peer_ifname, $xconn_ttl);
    }
    else {
	set_xconnect_port(ADD(), $ifname, $peer_ifname);
    }
} elsif ( $action eq 'DELETE' ) {
    if ( defined($l2tpifname) ) {
	set_xconnect_port_l2tpeth("remove", $ifname, $old_peer_ifname, $xconn_ttl);
    }
    else {
	set_xconnect_port(REMOVE(), $ifname, $old_peer_ifname);
    }
} elsif ( !defined($peer_ifname && defined($old_peer_ifname) ) ) {
    if ( defined($l2tpifname) ) {
	set_xconnect_port_l2tpeth("remove", $ifname, $old_peer_ifname, $xconn_ttl);
    }
    else {
	set_xconnect_port(REMOVE(), $ifname, $old_peer_ifname);
    }
} elsif ( defined($old_peer_ifname) ) {
    if ( defined($l2tpifname) ) {
	set_xconnect_port_l2tpeth("update", $ifname, $peer_ifname, $xconn_ttl);
    }
    else {
	set_xconnect_port(UPDATE(), $ifname, $peer_ifname);
    }
}

exit 0;

sub set_xconnect_port_l2tpeth {
    my ($cmd, $dp_ifname, $new_ifname, $xconn_ttl) = @_;
    my $ctrl = new Vyatta::VPlaned;

    my $ttl = "255";
    $ttl = $xconn_ttl
	if defined($xconn_ttl);

    $ctrl->store(
	"interfaces dataplane $dp_ifname xconnect",
	"l2tpeth -c $cmd $dp_ifname $new_ifname $ttl"
	);
}

sub set_xconnect_port {
    my ($cmd, $dp_ifname, $new_ifname) = @_;
    my $ctrl = new Vyatta::VPlaned;

    my $xconnect = XConnectConfig->new({
	cmd        => $cmd,
	dp_ifname  => $dp_ifname,
	new_ifname => $new_ifname,
				       });
	
    $ctrl->store_pb(
	"interfaces dataplane $dp_ifname xconnect",
	$xconnect,
	"vyatta:xconnect");
}
