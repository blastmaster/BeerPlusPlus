#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


BEGIN {
	no strict 'refs';
	my $time = time;
	*{'CORE::GLOBAL::time'} = sub { $time };
	use strict 'refs';
}


use Test::More 'no_plan';
BEGIN { use_ok('BeerPlusPlus::Command::Stock') }


use Time::Local;


my $time;

$time = 1286698210;
my ($expected) = grep { s/^0+// } unpack("B32", pack("N", 42));
is(join ("", get_time($time, qw(sec min hour))), $expected);


$time = time;
is_deeply([ parse_arg("880") ], [ $time, 44, 20 ]);
is_deeply([ parse_arg("Kx880") ], [ $time, 44, 20 ]);
is_deeply([ parse_arg("2Kx880") ], [ $time, 44, 40 ]);
is_deeply([ parse_arg("Bx44") ], [ $time, 44, 1 ]);
is_deeply([ parse_arg("3Bx44") ], [ $time, 44, 3 ]);
is_deeply([ parse_arg("KBx44") ], [ $time, 44, 21 ]);
is_deeply([ parse_arg("2KBx44") ], [ $time, 44, 41 ]);
is_deeply([ parse_arg("K3Bx44") ], [ $time, 44, 23 ]);
is_deeply([ parse_arg("2K3Bx44") ], [ $time, 44, 43 ]);

#my ($mon, $year) = get_time($time, qw(mon year));
#is_deeply([ parse_arg("880\@10.") ],
#		[ timelocal(10,10,10,10,$mon-1,$year), 44, 20 ]);
#is_deeply([ parse_arg("880\@10.10.") ],
#		[ timelocal(10,10,10,10,9,$year), 44, 20 ]);
#is_deeply([ parse_arg("880\@10.10.10") ], [ 1286698210, 44, 20 ]);


__END__
is_deeply([ parse_arg("880\@10.") ], [ $time, 44, 20 ]);
is_deeply([ parse_arg("880\@10.10.") ], [ $time, 44, 20 ]);
is_deeply([ parse_arg("880\@10.10.10") ], [ $time, 44, 20 ]);

