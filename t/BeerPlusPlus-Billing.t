#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


#use BeerPlusPlus::Test::Setup;
use BeerPlusPlus::Test::Database;
BEGIN { mkdir for glob "$BeerPlusPlus::Database::DATADIR/{users,stocks,bills}" }

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Billing', ':all') }

use Data::Printer;

#
# TEST CASES
# - handle same timestamp at the beginning
#

use BeerPlusPlus::User;
use BeerPlusPlus::Stock ':vars';

use constant SEC => 1;
use constant MIN => 60 * SEC;
use constant HOUR => 60 * MIN;
use constant DAY => 24 * HOUR;
use constant WEEK => 7 * DAY;

my $curtime = time;
# TODO use controlled random times for consuming to improve coverage?

#
# TEST SETUP
#

# assuming 3 users...
my ($uname1, $uname2, $uname3) = qw( user1 user2 user3 );
BeerPlusPlus::User->create($_) for ($uname1, $uname2, $uname3);
my ($user1, $user2, $user3) =
            map { BeerPlusPlus::User->new($_) } $uname1, $uname2, $uname3;
BeerPlusPlus::Stock->new($_) for ($uname1, $uname2);
my $u1_stock = BeerPlusPlus::Stock->new($uname1);
my $u2_stock = BeerPlusPlus::Stock->new($uname2);

# user 1 and 2 fill the stock in an interval of 1 week
my ($price1, $price2) = (42, 23);
$u1_stock->fill($curtime, $price1 - $DEPOSIT_BOTTLE, 6);
$u2_stock->fill($curtime + WEEK, $price2 - $DEPOSIT_BOTTLE, 6);

# user 1 and two drink beer at the same time (shortly after the first fill)
$user1->consume($curtime + SEC);	# drink from user 1
$user2->consume($curtime + MIN);	# drink from user 1

# user 3 joins and they drink more beer (at the same time)
$user1->consume($curtime + HOUR);	# drink from user 1
$user2->consume($curtime + HOUR);	# drink from user 1
$user3->consume($curtime + HOUR);	# drink from user 1

# after one week they meet again and drink some beer
# (user 2 added beer meanwhile)
$curtime += WEEK + DAY;
$user1->consume($curtime);			# drink from user 1, stock 1 is empty
$user2->consume($curtime + SEC);	# drink from user 2
$user3->consume($curtime + MIN);	# drink from user 2

# ... and another beer (at the same time)
$user1->consume($curtime + HOUR);	# drink from user 2
$user2->consume($curtime + HOUR);	# drink from user 2
$user3->consume($curtime + HOUR);	# drink from user 2

#
# at this moment do the first billing with following result:
#
# * user 1 has consumed 3 beer of (his own) stock 1 and 1 beer of stock 2
# * user 2 has consumed 2 beer of stock 1 and 2 beer of (his own) stock 2
# * user 3 has consumed 1 beer of stock 1 and 2 beer of stock 2
#
# * stock 1 is empty
# * stock 2 keeps 1 beer remaining
#

my %bills_1 = BeerPlusPlus::Billing->calculate();
is(scalar keys %bills_1, 3, "must be 3 bills");
# compare the bills in detail
my $bill1 = $bills_1{$uname1};
is($bill1->total, 1 * $price2, "compare total sum of user 1");
is_deeply({ $bill1->payments() }, { $uname2 => 1 * $price2 });
my $bill2 = $bills_1{$uname2};
is($bill2->total, 2 * $price1, "compare total sum of user 2");
is_deeply({ $bill2->payments() }, { $uname1 => 2 * $price1 });
my $bill3 = $bills_1{$uname3};
is($bill3->total, 1 * $price1 + 2 * $price2, "compare total sum of user 3");
is_deeply({ $bill3->payments() }, { $uname1 => 1 * $price1, $uname2 => 2 * $price2 });

$_->to_string() for values %bills_1;

# BALANCING HARDCORE TODO
#
my %balanced_bills = BeerPlusPlus::Billing->balance(%bills_1);
ok(not exists $balanced_bills{$uname1});
my $balanced2 = $balanced_bills{$uname2};
is($balanced2->total, 2 * $price1 - 1 * $price2, "compare total sum of user 2");
is_deeply({ $balanced2->payments() }, { $uname1 => 2 * $price1 - 1 * $price2 });
my $balanced3 = $balanced_bills{$uname3};
is($balanced3->total, 1 * $price1 + 2 * $price2, "compare total sum of user 3");
is_deeply({ $balanced3->payments() }, { $uname1 => 1 * $price1, $uname2 => 2 * $price2 });

#ok($u1_stock->is_empty(), "stock 1 is empty after consumption");
#is($u2_stock->level(), 1, "one beer remains in stock 2 after consumption");

$_->persist() for ($bill1, $bill2, $bill3);
ok(BeerPlusPlus::Billing->exists($_)) for ($uname1, $uname2, $uname3);

# user 1 fills the stock with 5 beer
$u1_stock->fill($curtime, $price1 - $DEPOSIT_BOTTLE, 5);
# after another week they meet again and drink again some beer
$curtime += WEEK + DAY;
$user3->consume($curtime);			    # drink from user 2
$user2->consume($curtime + SEC);	    # drink from user 1
$user3->consume($curtime + MIN);	    # drink from user 1
$user2->consume($curtime + HOUR);	    # drink from user 1
$user3->consume($curtime + HOUR + MIN); # drink from user 1
# after a while the next billing is calculated
my %bills_2 = BeerPlusPlus::Billing->calculate();
is(scalar keys %bills_2, 2, "must be 2 bills");
my $bill4 = $bills_2{$uname2};
is($bill4->total, 2 * $price1, "compare total sum of user 2");
my $bill5 = $bills_2{$uname3};
is($bill5->total, 2 * $price1 + 1 * $price2, "compare total sum of user 3");

