#! /usr/bin/env perl

use strict;
use warnings;
use Mojo::JSON;
use Digest::SHA1 qw(sha1_base64);

my $USERDIR = "../users";
mkdir $USERDIR unless -d $USERDIR;

for my $username (@ARGV) {
    my $pass = sha1_base64('lukeichbindeinvater');
    my %new_user = (
        pass => $pass,
        user => $username,
        counter => 0,
    );
    my $json = Mojo::JSON->new;
    my $data = $json->encode(\%new_user);
    open my $fh, '>', "$USERDIR/$username".".json" or die qq/cannot open $!/;
    print {$fh} $data;
    close $fh;
}
