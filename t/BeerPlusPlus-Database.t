#! /usr/bin/env perl

use strict;
use warnings;


use BeerPlusPlus::Test::Database;
use BeerPlusPlus::Test::Util 'silent';

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Database') }


my ($db, $id, $expected, $got) = (undef, 'entry', {}, {});
silent { $db = BeerPlusPlus::Database->new('test') };

ok(! defined $db->list(), "list returns undef if database is not initialized");

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


is($db->remove('<non-existent.file>'), undef, "removing non-existent file results in undef");

my $rm_id = 'test-remove';
$db->store($rm_id, {});
ok($db->remove($rm_id), "removing existent db-entry '$rm_id' results in true/1");
ok(! $db->exists($rm_id), "db-entry does not exist after deletion");

# TODO test remove-method w/o permissions (simply chmod/chown does not work
#      due to the user is still the owner and cannot be changed if not root)
#$db->store($rm_id, {});
#ok(! $db->remove($rm_id), "removing db-entry w/o permission fails");
#ok(defined $!, "failure during deletion of db-entry sets \$!");


$db->remove($_) for $db->list();
is($db->list(), 0, "list returns 0 if database is empty");


BeerPlusPlus::Test::Database::reset_datadir();

# TODO improve test
chmod 0000, "$BeerPlusPlus::Database::DATADIR";
silent { eval "BeerPlusPlus::Database->new('fail')" };
ok(! $?, "creating db w/o permissions fails fatally");


BeerPlusPlus::Test::Database::reset_datadir();

mkdir "$BeerPlusPlus::Database::DATADIR/245";
$db = BeerPlusPlus::Database->new(0xF5);
ok(defined $db->list(), "database is initialized");
is_deeply( [ $db->list() ], [], "database is still empty");

