#! /usr/bin/perl

use strict;
use warnings;
use Mojo::JSON;
use feature "say";

my @list = <../lib/foo/*.json>;
@list = grep { s/.*(?<=\/)(\w+)\.json/$1/ } @list;
my $user_hash = { users => \@list, };
my $json = Mojo::JSON->new;
my $data = $json->encode($user_hash);
open my $fh, '>', '../lib/foo/users.json' or die qq/cannot open $!/;
print {$fh} $data;
close $fh;
