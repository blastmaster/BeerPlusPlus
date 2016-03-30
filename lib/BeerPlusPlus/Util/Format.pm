package BeerPlusPlus::Util::Format;

use strict;
use warnings;

use feature 'say';


use parent 'Exporter';

our %EXPORT_TAGS = ( 'all' => [ qw(
		get_elapsed_in_words
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( get_elapsed_in_words );


use Time::Piece;
use Time::Seconds;


sub get_elapsed_in_words {
	my $then = localtime shift;
	my $now  = localtime shift;

	my $info;
	if ($then->dmy eq $now->dmy or $then+3*ONE_HOUR > $now) {
		$info = $then->strftime('at %H:%M');
	} elsif (($then+ONE_DAY)->dmy() eq $now->dmy()) {
		$info = $then->strftime('yesterday, %H:%M');
	} elsif ((my $diff = $now - $then) <= 3*ONE_DAY) {
		$info = sprintf '%d days ago, %s', $diff->days, $then->strftime('%H:%M');
	} elsif ($then->year == $now->year) {
		$info = $then->strftime('on %d.%m., %H:%M');
	} else {
		$info = $then->strftime('on %d.%m.%Y, %H:%M');
	}

	return $info;
}


1;

