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
	my $then = localtime (shift);
	my $now  = localtime (shift || time);

	my $prefix;

	# Same day OR next day within 3h
	if ($then->dmy eq $now->dmy or $then + 3*ONE_HOUR > $now) {
		$prefix = 'at'
	}
	# Next day
	elsif (($then+ONE_DAY)->dmy eq $now->dmy) {
		$prefix = 'yesterday,';
	}
	# Up to 3 days after
	elsif ((my $diff = $now - $then) <= 3*ONE_DAY) {
		$prefix = sprintf '%d days ago,', $diff->days +0.5;
	}
	# Same year
	elsif ($then->year == $now->year) {
		$prefix = 'on %d.%m.,';
	}
	else {
		$prefix = 'on %d.%m.%y,';
	}

	return $then->strftime("$prefix %R");
}


1;

