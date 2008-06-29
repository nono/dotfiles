#!/usr/bin/perl

use strict;
use vars qw($VERSION %IRSSI);
$VERSION = '0.1';
%IRSSI = (
    authors     => 'Bruno Michel',
    contact     => 'bmichel@menfin.info',
    name        => 'Forward',
    description => 'forward incoming messages to another channel',
    license     => 'GPLv2',
    commands    => "forward"
);

use Irssi;

use vars qw($server1 $chan1 $server2 $chan2 $active);

sub show_help() {
    my $help = $IRSSI{name}." ".$VERSION."
/forward help
        Show this help
/forward set<server1> <chan1> <server2> <chan2>
        Forward incoming messages from <server1>:<chan1> to <server2>:<chan2>
/forward stop
        Disable all forwarding

Example: /forward freenode #kwartoo geeknode #aprilchat
";
    print CLIENTCRAP '%B>>%n '.$help;
}

sub sig_privmsg ($$$$) {
	return unless $active;
	my ($server, $data, $nick, $address) = @_;
	my ($target, $text) = split / :/, $data, 2;
	if ($server1 == $server->{chatnet}) {
		if ($chan1 eq $target) {
			$server2->command("MSG $chan2 <$nick> ".$text);
		}
	}
}

sub sig_ownmsg ($$$) {
	return unless $active;
	my ($server, $text, $target) = @_;
	if ($server1 == $server->{chatnet}) {
		if ($chan1 eq $target) {
			$server2->command("MSG $chan2 <".$server->{nick}."> ".$text);
		}
	}
}

sub set_forward ($$$$) {
    my ($s1, $c1, $s2, $c2) = @_;
	$server1 = $s1;
	$server2 = Irssi::server_find_chatnet($s2);
	$chan1 = $c1;
	$chan2 = $c2;
	$active = 1;
    print CLIENTCRAP "%B>>%n Forwarding messages from $s1:$c1 to $s2:$c2";
}

sub stop_forward () {
	$active = 0;
    print CLIENTCRAP "%B>>%n Stop forwarding";
}

sub cmd_forward ($$$) {
    my ($arg, $server, $witem) = @_;
    return unless defined $server;
    my @args = split(/ /, $arg);
    if (@args < 1 || $args[0] eq 'help') {
		show_help();
    } elsif (@args[0] eq 'set') {
		shift @args;
		return unless @args;
		set_forward($args[0], $args[1], $args[2], $args[3]);
    } elsif (@args[0] eq 'stop') {
		remove_forward();
    }
}


Irssi::signal_add('event privmsg', \&sig_privmsg);
Irssi::signal_add('message own_public', \&sig_ownmsg);
Irssi::command_bind('forward' => \&cmd_forward);

print CLIENTCRAP '%B>>%n '.$IRSSI{name}.' '.$VERSION.' loaded: /forward help for help';

