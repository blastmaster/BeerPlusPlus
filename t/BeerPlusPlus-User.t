#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


BEGIN {
	use BeerPlusPlus::Database;
	use File::Temp 'tempdir';
	$BeerPlusPlus::Database::DATADIR = tempdir('t/db.XXXXXXX', CLEANUP => 1);
}

use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::User') }


my $name = 'test-name';
my $pass = 'test-pass';

ok(BeerPlusPlus::User->create($name, $pass), "create '$name' user successfully");
ok(BeerPlusPlus::User->exists($name), "user '$name' exists after creation");
is_deeply([ BeerPlusPlus::User->list() ], [ $name ], "listing existent users");

my $user = BeerPlusPlus::User->new($name);
ok(defined $user, "initialization of user succeeded");
is($user->get_name(), $name, 'test $user->get_name()');
ok($user->verify($user->hash($pass)), "test password varification");

is($user->get_count(), 0, "new user's count is 0");
is($user->increment(), $user->get_count(), "increment returns updated count");
is($user->get_count(), 1, "user's count is 1 after incrementation");

my $new_pass = 'new-test-pass';
ok($user->change_password($new_pass), "change password successfully");
ok($user->verify($new_pass), "verify user with new password successfully");
ok(! $user->verify($user->hash($pass)), "verification with old password fails");

my $other_name = 'other-test-name';
BeerPlusPlus::User->create($other_name, $pass);
is_deeply([ $user->list_others() ], [ $other_name ], "list others w/o itself");

my $other = BeerPlusPlus::User->new($other_name);
my @others = $user->get_others();
is(scalar @others, 1, "loaded the other user");
is(ref $others[0], 'BeerPlusPlus::User', "loaded user is object");
is_deeply($others[0], $other, "loaded user is equals to created other user");

