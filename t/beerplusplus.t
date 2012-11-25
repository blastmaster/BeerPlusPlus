use strict;
use warnings;
use Test::More;
use Test::Mojo;

use feature "say";

require_ok("BeerPlusPlus");

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);

done_testing();
