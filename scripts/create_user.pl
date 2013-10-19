#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


use Cwd 'abs_path';
use Digest::SHA qw(sha1_base64);
use File::Basename;
use Mojo::JSON;


my $USERDIR = abs_path(dirname($0) . "/../users");
$USERDIR =~ s/^\Q$ENV{PWD}\E/./; # relative path
mkdir $USERDIR and say "info: created directory $USERDIR" unless -d $USERDIR;

for my $username (@ARGV) {
	my $pass = sha1_base64('lukeichbindeinvater');
	my %new_user = (
		pass => $pass,
		user => $username,
		counter => 0,
	);

	my $json = Mojo::JSON->new;
	my $data = $json->encode(\%new_user);

	my $userfile = "$USERDIR/$username.json";
	unless (-f $userfile) {
		open my $fh, '>', $userfile or die qq/cannot open $userfile: $!/;
		print {$fh} $data;
		close $fh or warn "cannot close $userfile: $!";
	} else {
		say STDERR "warn: user '$username' already exists!";
	}
}

