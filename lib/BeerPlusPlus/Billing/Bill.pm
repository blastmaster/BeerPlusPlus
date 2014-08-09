package BeerPlusPlus::Billing::Bill;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Billing::Bill - data structure for creating bills

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use BeerPlusPlus::Billing::Bill;

=head1 DESCIRPTION

=cut


use POSIX 'ceil';


sub new($$@) {
	my $class = shift;
	my $user = shift;
	my @consumptions = sort { $a->{timestamp} <=> $b->{timestamp} } @_; # TODO write test to check this!

	my $self = {
		user => $user,
		consumptions => \@consumptions,

		# payments
		# total
	};

	return bless $self, $class;
}

sub user($) {
	my $self = shift;

	return $self->{user};
}

sub consumptions($) {
	my $self = shift;

	return $self->{consumptions};
}

sub payments($) {
	my $self = shift;

	unless (defined $self->{payments}) {
		my %payments;
		for my $consumption (@{$self->consumptions}) {
			my $charge = $consumption->{charge};
			my $receiver = $charge->stock->get_user();
			$payments{$receiver} = 0 unless defined $payments{$receiver};
			$payments{$receiver} += $charge->price();
		}

		# round up total amount of the receiver
		%payments = map { $_ => ceil($payments{$_}) } keys %payments;

		$self->{payments} = \%payments;
	}

	return $self->{payments};
}

sub total($) {
	my $self = shift;

	unless (defined $self->{total}) {
		my $total = 0;
		for my $amount (values $self->payments()) {
			$total += $amount;
		}

		$self->{total} = $total;
	}

	return $self->{total};
}

sub offset($) {
	my $self = shift;

	return scalar $self->consumptions();
}

#sub settle(



__END__
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

sub to_string($) {
	my $self = shift;
}


1;
__END__

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Innercircle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

