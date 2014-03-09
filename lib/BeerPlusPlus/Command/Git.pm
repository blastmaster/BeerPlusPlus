package BeerPlusPlus::Command::Git;

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Command ':dev';
use BeerPlusPlus::Database;
use File::Basename;


sub name() {
	return 'git';
}

sub description() {
	return "managing databases via git";
}

sub usage() {
	return "<store> <git-command>";
}

sub execute(@) {
	my $store = shift or fatal("no store given"), return 0;
	my $gitcmd = shift || 'status';
	my @params = @_;

	my $db = BeerPlusPlus::Database->new($store);
	my $store_dir = dirname($db->fullpath('location'));

	chdir $store_dir;
	local $" = "' '";
	exec "git $gitcmd '@params'";
}


1;

