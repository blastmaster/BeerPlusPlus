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
is($stock->get_account(), undef, "user's account is undefined if unset");
is(scalar $stock->get_charges(), 0, "stock is empty after creation");

my $time = 1286698210;
my $amount = $BOTTLES_PER_CRATE;
my $price = 880 / $amount;
ok($stock->fill($time, $price, $amount), "adding a crate successfully");
my @charges = $stock->get_charges();
is(scalar @charges, 1, "stock contains one crate after adding");

my $charge = $charges[0];
is($charge->time(), $time, "check (re)stored data structure (time)");
is($charge->price(), $price, "check (re)stored data structure (price)");
is($charge->amount(), $amount, "check (re)stored data structure (amount)");

my $otime = $time - 245;
my $oprice = 980 / $amount;
$stock->fill($otime, $oprice, $amount);
is_deeply([ map { $_->time } $stock->get_charges() ], [ $otime, $time ],
		"crates are sorted by time");

is($charge->date("%d-%02d-%02d %02d:%02d:%02d", reverse 0 .. 5),
		"2010-10-10 10:10:10", "date formatting works");

is_deeply([ map { $_->bottles } $stock->get_charges ],
		[ (64.5) x $BOTTLES_PER_CRATE,  (59.5) x $BOTTLES_PER_CRATE ],
		"must be 40 bottles sorted by time");

my $a_holder = 'Netzbiotop Dresden e.V.';
my $a_number = 4655221005;
my $a_code = 85090000;
ok($stock->set_account($a_holder, $a_number, $a_code),
		"updating the user's account data succeeds");
my $account = $stock->get_account();
is($account->holder(), $a_holder, "stored account holder matches");
is($account->number(), $a_number, "stored account number matches");
is($account->code(), $a_code, "stored account code matches");

