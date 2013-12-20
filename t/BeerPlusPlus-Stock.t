#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Test::Database;

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Stock', ':vars') }


my $user = 'test';
my $stock = BeerPlusPlus::Stock->new($user);
is($stock->get_user(), $user, "equality of user names");
is(scalar $stock->get_crates(), 0, "stock is empty after creation");

my $time = time;
my $price = 880;
ok($stock->add_crate($time, $price), "adding a crate succeeds");
my @crates = $stock->get_crates();
is(scalar @crates, 1, "stock contains one crate after adding");
is_deeply($crates[0], { time => $time, price => $price },
		"check data structure of returned crate");

my $otime = $time - 245;
my $oprice = 980;
$stock->add_crate($otime, $oprice);
is_deeply([ $stock->get_crates() ], [ { time => $otime, price => $oprice },
		{ time => $time, price => $price } ], "crates are sorted by time");

