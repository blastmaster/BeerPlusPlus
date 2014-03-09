package BeerPlusPlus::Command;

use strict;
use warnings;

use feature 'say';


use parent 'Exporter';

our @EXPORT = qw(
	find run help
);
our @EXPORT_OK = qw(
	commands
	info fatal $BIN $BASE %SUBCMDS
);
our %EXPORT_TAGS = ( dev => [ qw( info fatal $BIN $BASE %SUBCMDS ) ] );


use File::Basename;
use Module::Pluggable
		search_path => __PACKAGE__,
		sub_name => 'commands';


our $BIN = basename($0);
our $BASE = dirname($0) . '/..';
our %SUBCMDS = map { s/.+:://r =~ tr /[A-Z]/[a-z]/r => $_ } commands();

my $ACTION = undef;


sub find($) {
	my $action = shift;

	my $command = $SUBCMDS{$action};
	if (defined $command) {
		eval "require $command";
		$ACTION = $command;
		return 1;
	}

	return 0;
}

sub run(@) {
	my @args = @_ ? @_ : @ARGV;

	no strict 'refs';
	my $status = &{"$ACTION\::execute"}(@args);
	use strict 'refs';

	return $status;
}

sub help() {
	say STDERR "usage: $BIN <command> [options] [arg...]";
	say STDERR "       $BIN --help";

	eval "require $_" for values %SUBCMDS;
	say "\nCommands:";
	while (my ($name, $cmd) = each %SUBCMDS) {
		printf "  %-6s   %s\n", $name, $cmd->description();
	}
	say "\nSee '$BIN help <command>' for more information!";
}


sub info($) {
	say "info: ", shift;
}

sub fatal($;$) {
	my $message = shift;
	my $exitcode = shift || 1;

	say STDERR "fatal: ", $message;

	exit $exitcode;
}


1;

