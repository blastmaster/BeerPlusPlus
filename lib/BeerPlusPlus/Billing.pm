package BeerPlusPlus::Billing;

use strict;
use warnings;

use feature 'say';


use parent 'Exporter';

our %EXPORT_TAGS = ( all => [ qw(
		associate calculate_bills distribute_guest_bill calculate_checksums
		settle_bills
) ] );
our @EXPORT_OK = ( @{$EXPORT_TAGS{all}} );



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


use BeerPlusPlus::Billing::Bill;
use BeerPlusPlus::Database;
use BeerPlusPlus::Stock;
use BeerPlusPlus::User;
use POSIX 'ceil';

use Data::Printer;
use Time::Piece;


my $DB = BeerPlusPlus::Database->new('bills');


sub new($) {
	my $class = shift;

	my $self = bless {}, $class;

	$self->load_users();
	$self->load_stocks();
	$self->load_bills();

	return $self;
}

sub load_users($) {
	my $self = shift;

	my @names = BeerPlusPlus::User->list();
	my %users = map { $_ => BeerPlusPlus::User->new($_) } @names;
	my @users = values %users;#map { $users{$_} } sort keys %users;

	$self->{users} = \%users;

	return;
}

sub get_usernames($) {
	my $self = shift;

	return keys $self->{users};
}

sub get_users($) {
	my $self = shift;

	return values $self->{users};
}

sub get_user($$) {
	my $self = shift;
	my $name = shift;

	return $self->{users}->{$name};
}

sub load_stocks($) {
	my $self = shift;

	my @stocks = map { BeerPlusPlus::Stock->new($_) } BeerPlusPlus::Stock->list();
	my @charges = sort { $a->time <=> $b->time } map { $_->get_charges() } @stocks;

	$self->{charges} = \@charges;

	return;
}

sub load_bills($) {
	my $self = shift;

	my @bills = map { $DB->load($_) } $DB->list();
}


sub associate(\@\@);
sub calculate_bills(\@\%);
sub distribute_guest_bill(\%@);
sub calculate_checksums(%);
sub settle_bills(\%\%);


sub calculate($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	my @stocks = map { BeerPlusPlus::Stock->new($_) } BeerPlusPlus::Stock->list();
	my @charges = sort { $a->time <=> $b->time } map { $_->get_charges() } @stocks;
	my %users = map { $_ => BeerPlusPlus::User->new($_) } BeerPlusPlus::User->list();
	my @users = values %users;#map { $users{$_} } sort keys %users;
	my @timestamps = sort map { $_->get_timestamps() } @users;

	my %consumptions = associate(@timestamps, @charges);
	my %bills = calculate_bills(@users, %consumptions);
	distribute_guest_bill(%bills, @users{qw(blastmaster 8ward)});
	# TODO swap calculation of checksums and settling of bills to avoid
	#      doubled interation etc. (bills can be settled w/o checksums!)
	my %checksums = calculate_checksums(%bills);
	settle_bills(%bills, %checksums);
	# TODO mail both original bills and settled ones

	return %bills;
}

sub associate(\@\@) {
	my @timestamps = @{(shift)};
	my @charges = @{(shift)};

	my %consumptions;
	my $cur_charge = shift @charges;
	my $cur_charge_remain = $cur_charge->amount();
	my $count = 0;
	for my $timestamp (@timestamps) {
#		say "skip:  $timestamp < ", 1383407687 + 600 if $timestamp < 1383407687 + 600;
		$count++;
#		next if $timestamp < 1383407687 + 600;
		$count--;
		last if $timestamp > 1383407687 + 120000;
		unless ($cur_charge_remain) {
			unless (@charges) {
				warn "not enough beer...";
				last;
			}
			$cur_charge = shift @charges;
			$cur_charge_remain = $cur_charge->amount;
		}

		warn "INCONSISTENCY: TIMESTAMP < CHARGE-TIME"
				if $timestamp < $cur_charge->time();

		$consumptions{$timestamp} = [] unless defined $consumptions{$timestamp};
		push $consumptions{$timestamp}, $cur_charge;

		$cur_charge_remain--;
	}
	say "skipped $count in total";

	return %consumptions;
}


sub calculate_bills(\@\%) {
	my @users = @{(shift)};
	my %consumptions = %{(shift)};

#	open B, '>', "consumed." . time or die $!;
#	say "consumed.", time;
	my %bills;
	#
	# consumptions = {
	#   1234567890 => [
	#     charge[44], charge[44], charge[44], charge[49], charge[49], charge[49]
	# }
	#
	# paetti  <<  charge[44]         |         8ward   <<  charge[44]
	# 8ward   <<  charge[44]         |         8ward   <<  charge[44]
	# paetti  <<  charge[44]         |         marcel  <<  charge[44]
	# marcel  <<  charge[49]         |         paetti  <<  charge[49]
	# 8ward   <<  charge[49]         |         paetti  <<  charge[49]
	# marcel  <<  charge[49]         |         marcel  <<  charge[49]
	# ---                            |         ---
	# paetti  >>  88                 |         paetti  >>  98
	# 8ward   >>  93                 |         8ward   >>  88
	# marcel  >>  98                 |         marcel  >>  93
	#
	for my $user (@users) {
		my $name = $user->get_name();
#		say "calculating bill for $name...";

		my @consumptions;
		for my $timestamp (sort $user->get_timestamps()) {
#			last unless defined $consumptions{$timestamp};
			next unless defined $consumptions{$timestamp};
			my $charge = shift $consumptions{$timestamp};
			die unless defined $charge;

			unless (@consumptions) {
				my $t = localtime $timestamp;
#				say "$name consumed his first beer from ",
#						$charge->stock->get_user, " @ ", $t->dmy, 'T', $t->hms;
				printf "> %-12s   %-12s  @  %sT%s\n", $name,
						$charge->stock->get_user, $t->dmy, $t->hms;
			}

			push @consumptions, {
				timestamp => $timestamp,
				charge => $charge,
			};

#			my $t = localtime $timestamp;
#			say B "$name consumed a beer at $t from ", $charge->stock->get_user;
		}

		$bills{$name} = BeerPlusPlus::Billing::Bill->new($user, @consumptions);
	}
#	close B or warn $!;

	return %bills;
}

sub distribute_guest_bill(\%@) {
	my $bills = shift;
	my @guest_ambassadors = @_;

	my $guest_bill = delete $bills->{guest};
	my $next = 0;
	for my $consumption (@{$guest_bill->consumptions}) {
		my $ambassador = $guest_ambassadors[$next];
		my $name = $ambassador->get_name();

		# TODO warn if ambassador is not billed
		push $bills->{$name}->consumptions, $consumption;

		$next = ++$next % @guest_ambassadors;
	}

	for my $ambassador (@guest_ambassadors) {
		my $name = $ambassador->get_name();
		my $bill = $bills->{$name};

		@{$bill->consumptions} = sort {
			$a->{timestamp} <=> $b->{timestamp}
		} @{$bill->consumptions};
	}

	return;
}

sub calculate_checksums(%) {
	my %bills = @_;

	my %checksums;
	while (my ($name, $bill) = each %bills) {
		my $payments = $bill->payments();
		while (my ($receiver, $amount) = each $payments) {
			$checksums{$receiver} = {} unless defined $checksums{$receiver};
			$checksums{$receiver}->{$name} = $amount;
		}
	}

	return %checksums;
}

sub settle_bills(\%\%) {
	my $bills = shift;
	my $checksums = shift;

	my @receivers = sort keys $checksums;
	for my $receiver (@receivers) {
		my $payments = $checksums->{$receiver};

		for my $name (keys $payments) {
			next if $name eq $receiver;
			next unless defined $checksums->{$name};

			# TODO move outside loop
			my $bill = $bills->{$receiver};
#			next unless defined $bill->{payments}->{$name};

			my $receive_amount = $payments->{$name};		# user -> receiver
			my $pay_amount = $bill->{payments}->{$name};	# receiver -> user

			if ($pay_amount > $receive_amount) {
				# delete user->receiver from receiver(checksums)
				delete $checksums->{$receiver}->{$name};
				# delete user->receiver from user(bill)
				delete $bills->{$name}->{payments}->{$receiver};

				# substract receiver->user from receiver(bill)
				$bill->{payments}->{$name} -= $pay_amount - $receive_amount;
				# substract receiver->user from user(checksums)
				$checksums->{$name}->{$receiver} -= $receive_amount;
			} elsif ($pay_amount < $receive_amount) {
				# delete receiver->user from user(checksums)
				delete $checksums->{$name}->{$receiver};
				# delete receiver->user from receiver(bill)
				delete $bill->{payments}->{$name};

				# substract user->receiver from user(bill)
				$bills->{$name}->{payments}->{$receiver} = $receive_amount - $pay_amount;
				# substract user->receiver from receiver(checksums)
				$checksums->{$receiver}->{$name} -= $pay_amount;
			} else {
				delete $bill->{payments}->{$name};
				delete $bills->{$name}->{payments}->{$receiver};

				delete $checksums->{$receiver}->{$name};
				delete $checksums->{$name}->{$receiver};
			}
		}

		delete $checksums->{$receiver} unless %{$checksums->{$receiver}};
	}

	return;
}


1;



__END__

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

	return \@charges, %charges;
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

