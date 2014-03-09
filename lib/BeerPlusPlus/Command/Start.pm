package BeerPlusPlus::Command::Start;

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Command ':dev';
use Cwd 'abs_path';
use File::Temp 'tempfile';
use Getopt::Long 'GetOptionsFromArray';


sub name() {
	return 'start';
}

sub description() {
	return "starts the beer++ web-server";
}

sub usage() {
	return "[--dev]";
}

sub execute(@) {
	GetOptionsFromArray(\@_, 'dev' => \my $development);

	if ($development) {
		my @watch = map { "$BASE/$_" } qw( lib public templates );
		info_watch(@watch);

		my @opts = map { -w => $_ } @watch;
		my $script = gen_script($BASE);
		system 'morbo', @opts, $script;
	} else {
		require Mojolicious::Commands;
		Mojolicious::Commands->start_app('BeerPlusPlus', 'daemon');
	}

	return 1;
}

sub info_watch(@) {
	my @watch = @_;

	return unless @watch;

	@watch = map { abs_path($_) =~ s/^$ENV{HOME}/~/r } @watch;
	info("watching following directories\n  * " . join "\n  * ", @watch);
}

sub gen_script($) {
	my $base = shift;

	my $template = 'beer++start.XXXXXXX';
	my ($fh, $script) = tempfile($template, UNLINK => 1, TMPDIR => 1);

	my $lib = abs_path("$base/lib");
	print $fh map { s/%LIB%/$lib/r } <DATA>;

	return $script;
}


1;
__DATA__
#! /usr/bin/env perl

use strict;
use warnings;


BEGIN { unshift \@INC, "%LIB%" }


require Mojolicious::Commands;
Mojolicious::Commands->start_app('BeerPlusPlus');

