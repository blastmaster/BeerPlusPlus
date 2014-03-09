package BeerPlusPlus::Command::Stock;

use strict;
use warnings;

use feature 'say';


use parent 'Exporter';

# TODO use :test tag to export logical subroutines
our @EXPORT = qw( parse_arg get_time );


use BeerPlusPlus::Command ':dev';
use BeerPlusPlus::Stock ':vars';
use Time::Local;

=head1 USAGE

  $ beer++ stock <user> [charge-spec]

=over 4

=cut


sub name() {
	return 'stock';
}

sub description() {
	return "managing beer++ stocks";
}

sub usage() {
	return "<user> [charge-spec...]\n\ncharge-spec: "
			. "[[[<n>K][<m>B]]x]<price(*20 if K)>[@<D>.[<M>.[<Y>[T<H>:<m>:<s>]]]]";
}

sub execute(@) {
	my $user = shift or fatal("no user specified"), return 1;
	my @specs = @_;

	my $stock = BeerPlusPlus::Stock->new($user);
	unless (@specs) {
		unless (BeerPlusPlus::Stock->exists($user)) {
			fatal("user does not exist");
			return 1;
		}
		return list_charges($stock);
	} else {
		return add_charges($stock, @specs);
	}
}


sub list_charges($) {
	my $stock = shift;

	my @charges = $stock->get_charges();
	unless (@charges) {
		info("no charges listed");
		return;
	}

#	$DEPOSIT_CRATE = $DEPOSIT_BOTTLE = 0;

	my $total = 0;
	for my $charge ($stock->get_charges()) {
		say $charge->to_string();
		$total += $charge->price * $charge->amount;
	}
#	say join "\n", map { $_->to_string } $stock->get_charges();
#	my $total = 0;
	printf "total:%39s", sprintf "%d.%02d€\n", $total / 100, $total % 100;
}

sub add_charges($@) {
	my $stock = shift;
	my @specs = @_;

	$stock->fill(parse_arg($_)) for @specs;

	return 1;
}

=item parse_arg($spec)

=cut

#
# [[[<n>K]|[<m>B]]x]<price[*20ifK|*1ifB]>[@<day>.[<mon>.[<year>[T<hour>:<min>:<sec>]]]]
#
sub parse_arg($) {
	local $_ = shift;

	# TODO inform user about wrong argument syntax and improve regex
	/^((\d*[kK])?(\d*[bB])?x)?\d+(@\d{1,2}.(\d{1,2}.(\d{2,4})?)?(T\d{2}:\d{2}:\d{2})?)?$/ or die;

	my ($time, $price, $amount);

	my ($m, $y) = get_time(time, qw(mon year));

	my ($_day, $_mon, $_year, $_hour, $_min, $_sec)
			= get_time(time, qw(day mon year hour min sec));

	if (my ($day) = /\@(\d+)\./) {
		my ($mon) = (/\@$day\.(\d+)\./, $_mon);
		my ($year) = (/\@$day\.$mon\.(\d+)/, $_year);
		my ($hour, $min, $sec)
				= (/\@$day\.$mon\.${year}T(\d{2}):(\d{2}):(\d{2})/,
				$_hour, $_min, $_sec);
		$time = timelocal($sec, $min, $hour, $day, $mon -1, $year);
	} else {
		$time = time;
	}

	($price) = /(?:^|x)(\d+)(?:@|$)/;

	if (/^(\d*)[kK]x/) {
		$amount = ($1 || 1) * $BOTTLES_PER_CRATE;
		$price /= $BOTTLES_PER_CRATE;
	} elsif (/^(\d*)[bB]x/) {
		$amount = $1 || 1;
	} elsif (/^(\d*)[kK](\d*)[bB]x/) {
		$amount = ($1 || 1) * $BOTTLES_PER_CRATE + ($2 || 1);
	} else {
		$amount = $BOTTLES_PER_CRATE;
		$price /= $BOTTLES_PER_CRATE;
	}

	return $time, $price, $amount;
}

sub get_time(;$@) {
	my $time = shift || time;
	my @fields = @_ ? @_ : qw(sec min hour day mon year);

	my ($sec, $min, $hour, $day, $mon, $year) = localtime $time;
	$mon += 1;
	$year += 1900;

	my %fields = (
		sec => $sec,
		min => $min,
		hour => $hour,
		day => $day,
		mon => $mon,
		year => $year,
	);

	return @fields{@fields};
}

=back

=cut

