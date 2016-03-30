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


my $MAX_HOURS_AGO = 3 * ONE_HOUR;
my $MAX_DAYS_AGO  = 3 * ONE_DAY;


sub get_elapsed_in_words {
	my $then = localtime (shift);
	my $now  = localtime (shift || time);

	my $t_day = _truncate_hours($then);
	my $n_day = _truncate_hours($now);

	my $prefix;

	# Same day OR next day within 3h
	if ($t_day == $n_day or $then + $MAX_HOURS_AGO > $now) {
		$prefix = 'at'
	}
	# Next day
	elsif ($t_day + ONE_DAY == $n_day) {
		$prefix = 'yesterday,';
	}
	# Up to 3 days after
	elsif ((my $diff = $n_day - $t_day) <= $MAX_DAYS_AGO) {
		$prefix = sprintf '%d days ago,', $diff->days;
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

# Truncates hours to 00:00:00
sub _truncate_hours {
	return localtime->strptime(shift->strftime('%D00:00'), '%D%R');
}


1;

