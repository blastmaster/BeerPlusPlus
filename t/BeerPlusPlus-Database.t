#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Database') }


use File::Temp 'tempdir';
sub silent(&);


$BeerPlusPlus::Database::DATADIR = tempdir('t/db.XXXXXXX', CLEANUP => 1);

my $db = BeerPlusPlus::Database->new('test');
my ($id, $expected, $got) = 'entry';

ok(! $db->exists($id), "db-entry '$id' does not exist");
$expected->{test} = 'succeeded';
ok($db->store($id, $expected), "store db-entry '$id' successfully");

ok($db->exists($id), "db-entry '$id' does exist (after creation)");
ok($got = $db->load($id), "load db-entry '$id' successfully");
is_deeply($got, $expected, "loaded db-entry is equals to stored one");

my $empty_entry = $db->load('<non-existent.file>');
ok(defined $empty_entry, "loading a non-existent file is not 'undef'");
is_deeply($empty_entry, {}, "loading a non-existent file results in empty hash-reference");

silent
{
	my $ua_id = 'unaccessable';
	$db->store($ua_id, {});
	chmod 0000, $db->fullpath($ua_id);
	ok(! defined $db->load($ua_id), "loading unaccessable file results in 'undef'");
};


$BeerPlusPlus::Database::DATADIR = tempdir('t/db.XXXXXXX', CLEANUP => 1);
chmod 0000, "$BeerPlusPlus::Database::DATADIR";
eval "BeerPlusPlus::Database->new('fail')";
ok(! $?, "creating db w/o permissions fails fatally");



sub silent(&) {
	local *STDERR;
	open STDERR, '>', '/dev/null' or die "cannot open /dev/null: $!";
	shift->();
	close STDERR or warn "cannot close /dev/null: $!";
}

