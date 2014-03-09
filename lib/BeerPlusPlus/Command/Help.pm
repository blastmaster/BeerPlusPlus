package BeerPlusPlus::Command::Help;

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Command ':dev';
use File::Temp 'tempfile';
use Getopt::Long 'GetOptionsFromArray';
use Pod::Man;


sub name() {
	return 'help';
}

sub description() {
	return "shows detailed help to specified command";
}

sub usage() {
	return "[--short] <command>";
}

sub execute(@) {
	GetOptionsFromArray(\@_, 'short' => \my $short);
	my $command = shift || 'help';

	fatal("unknown command") unless defined $SUBCMDS{$command};

	eval "require $SUBCMDS{$command}";
	if ($short) {
		short_usage($command);
	} else {
		long_usage($command);
	}

	return 1;
}

sub short_usage($) {
	my $command = shift;

	no strict 'refs';
	my $usage = &{"$SUBCMDS{$command}::usage"};
	use strict 'refs';

	$usage = join "\n       ", split /\n/, $usage;
	say STDERR "usage: $BIN $command $usage";
}

sub long_usage($) {
	my $command = shift;

	my $parser = Pod::Man->new(
		center => "Beer++ Command Documentation",
		name => "beer++ $command",
	);

	my $template = "beer++$command.XXXXXXX";
	my ($fh, $tempfile) = tempfile($template, UNLINK => 1, TMPDIR => 1);

	my $module_file = module2path($SUBCMDS{$command});
	if ($module_file) {
		$parser->parse_from_file($module_file, $tempfile);
		if (<$fh>) {
			system "man $tempfile";
		} else {
			info("no detailed help available");
			short_usage($command);
		}
	} else {
		short_usage($command);
	}
}

sub module2path($) {
	my $module = shift;

	$module =~ s/::/\//g;
	$module =~ s/$/.pm/g;

	return $INC{$module};
}


1;

