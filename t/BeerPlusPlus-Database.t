
use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Database') }


use File::Temp 'tempdir';


$BeerPlusPlus::Database::DATADIR = tempdir('t/db.XXXXXXX', CLEANUP => 1);

my $db = BeerPlusPlus::Database->new('test');
my ($id, $expected, $got) = 'entry';

ok(! $db->exists($id), "db-entry '$id' does not exist");
$expected->{test} = 'succeeded';
$db->store($id, $expected);

ok($db->exists($id), "db-entry '$id' does exist (after creation)");
$got = $db->load($id);
is_deeply($got, $expected, "loaded db-entry is equals to stored one");

