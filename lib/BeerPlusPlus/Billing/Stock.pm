package BeerPlusPlus::Billing::Stock;

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Stock;


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

