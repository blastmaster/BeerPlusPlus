#! /usr/bin/env perl

use strict;
use warnings;
use Mojo::JSON;
use Digest::SHA1 qw(sha1_base64);

use feature "say";

my $username = $ARGV[0] or die qq/no username given/;
my $pass = sha1_base64('lukeichbindeinvater');
my %new_user = (
    pass => $pass,
    user => $username,
    counter => 0,
);
my $json = Mojo::JSON->new;
my $data = $json->encode(\%new_user);
open my $fh, '>', "../lib/foo/".$username.".json" or die qq/cannot open $!/;
print {$fh} $data;
close $fh;
