package BeerPlusPlus::Billing;

use strict;
use warnings;

use feature 'say';

#
# 1. order stock charges by time
# 2. order user consumed beer by time
# 3. relate user to charge by time
# 4. calculate bill
# 5. generated detailed report
#
#   * average beer price
#   * periods and pricings
#


use BeerPlusPlus::Stock;


sub serialize_stocks();

sub calculate {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	my ($charges, %charges) = serialize_stocks();
}

sub serialize_stocks() {
	my @charges;
	my %charges;
	for my $entry (BeerPlusPlus::Stock->list()) {
		my $stock = BeerPlusPlus::Stock->new($entry);

		for my $charge ($stock->get_charges()) {
			my $bill_charge = BeerPlusPlus::Bill::Charge->new($charge);

			push @charges, $bill_charge;

			my $time = $charge->time;
			$charges{$time} = [] unless defined $charges{$time};
			push $charges{$time}, $bill_charge;
		}
	}

	my \@charges, %charges;
}


package BeerPlusPlus::Billing::LinkedCharge;

sub new($$) {
	my $class = shift;
	my $charge = shift;

	my $self = {
		charge => $charge,
		bottles => $charge->amount,
		consumers => {},
	};

	return bless $self, $class;
}

sub is_empty($) {
	my $self = shift;

	return $self->{bottles} == 0;
}

sub consume_by($$) {
	my $self = shift;
	my $user = shift;

	$self->{bottles}--;

	$self->{consumers}->{$user} = 0
			unless defined $self->{consumers}->{$user};
	$self->{consumers}->{$user}++;
}

sub get_stock($) {
	my $self = shift;

	return $self->{charge}->stock();
}


package BeerPlusPlus::Billing::Bill;

use BeerPlusPlus::Database;

sub new($$) {
	my $class = shift;
	my $user = shift;

	my $self = {
		user => $user,
		pay => {},
	};

	return bless $self, $class;
}

=item $bill->pay($charge, $amount)

Adds an amount of beer from the given charge to the list of beers to be paid.
The C<charge> argument must be an instance of C<BeerPlusPlus::Billing::Charge>.

=cut

sub pay($$$) {
	my $self = shift;
	my $charge = shift;
	my $amount = shift;

	my $stock = $charge->get_stock();
	my $user = $stock->get_user();

	$self->{pay}->{$user} = [] unless defined $self->{pay}->{$user};
	push $self->{pay}->{$user}, ($charge->{charge}->price) x $amount;
}

sub total($) {
	my $self = shift;

	my $total = 0;
	my %total;
	while (my ($user, $beers) = each $self->{pay}) {
		my $sum = 0;
		$sum += $_ for @{$beers};
		$total += $sum;
		$total{$user} = $sum;
	}

	return wantarray ? $total : %total;
}


1;

