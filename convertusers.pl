#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }

use BeerPlusPlus::User;

sub backup
{
    my $filename = shift;
    if ( -f $filename ) {
        rename $filename, "$filename.bak";
    }
    else {
        warn "no such filename";
    }
}

my $user = BeerPlusPlus::User->new('users');
my @users = ();
if (@ARGV) {
    @users = map { $user->get_user($_) } @ARGV;
}
else {
    @users = $user->get_users();
}

for my $userhash (@users) {
    my $username = $userhash->{user};
    my $filename = "$user->{datadir}/$username.json";
    backup($filename);
    my $tmpcount = $userhash->{counter};
    my @times = ();
    push @times, time for(0 .. $tmpcount - 1);
    $user->{user} = $username;
    $user->{pass} = $userhash->{pass};
    delete $user->{counter};
    $user->{times} = \@times;
    $user->persist();
}
