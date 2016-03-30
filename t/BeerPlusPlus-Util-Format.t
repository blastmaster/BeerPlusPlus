#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Util::Format') }


# Use this for testing 'yesterday' branch
my $then = 1459124201;
my $now  = 1459296780;
my $now2 = 1459298761;

say get_elapsed_in_words($then, $now);
say get_elapsed_in_words($then, $now2);

