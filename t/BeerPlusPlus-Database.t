#! /usr/bin/env perl

use strict;
use warnings;


use BeerPlusPlus::Test::Database;
use BeerPlusPlus::Test::Util 'silent';

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Database') }


my $db = BeerPlusPlus::Database->new('test');
my ($id, $expected, $got) = 'entry';

is($db->list(), undef, "list returns undef if database is not initialized");

ok(! $db->exists($id), "db-entry '$id' does not exist");
$expected->{test} = 'succeeded';
ok($db->store($id, $expected), "store db-entry '$id' successfully");
is($db->list(), 1, "database contains one entry");

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

	ok(! $db->store("undef hash-ref"), "abort if hash-reference is undef");

	my $aobj = bless [ 'data', 'xyz' ], 'Test';
	ok(! $db->store("bar", $aobj), "store blessed array-reference fails");
};

my $hobj = bless { data => 'xyz' }, 'Test';
ok($db->store("bhr", $hobj), "store blessed hash-reference succeeds");


my $e_id = 'empty';
open F, '>', $db->fullpath($e_id) and close F; # touch file
ok($got = $db->load($e_id), "loading empty data-file");
is_deeply($got, {}, "loaded hash of empty file is empty");


unlink for glob $db->{base} . "/*";
is($db->list(), 0, "list returns 0 if database is empty");


BeerPlusPlus::Test::Database::reset_datadir();

chmod 0000, "$BeerPlusPlus::Database::DATADIR";
eval "BeerPlusPlus::Database->new('fail')";
ok(! $?, "creating db w/o permissions fails fatally");

