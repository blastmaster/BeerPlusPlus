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

# TODO:
# implement distribute guest_bill


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


use BeerPlusPlus::Database;
use BeerPlusPlus::Stock qw( :vars );
use BeerPlusPlus::User;

use Data::Printer;
use Time::Piece;

my $DB = BeerPlusPlus::Database->new('bills');

=item BeerPlusPlus::Billing->list()

Lists all existent users and returns the list of all names.

=cut

sub list() {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	return $DB->list();
}

=item BeerPlusPlus::Billing->exists($username)

Returns true/1 if the user exists already; otherwise false/0.

=cut

sub exists($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $name = shift;

	return $DB->exists($name);
}

# steps to do:
# 1. load users
# 2. associate timestamps to users
# 3. load stocks
# 4. associate sorted timestamps to charges
# 5. calculate for each timestamp which user consumed from which charge
# 6. load last markers
# 7. discard timestamps before markers
# 8. calculate bills
# 9. balance each bill
# 10. ballance all bills
# 11. set markers for currently calculated bills

sub calculate($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

    # 1. load users
    # 2. associate timestamps to users
    my %users;
    my %user_timestamps;
    my %billings;
    my %last_markers;
    for my $username (BeerPlusPlus::User->list()) {
        my $user = BeerPlusPlus::User->new($username);
        $users{$username} = $user;
        my $billing = BeerPlusPlus::Billing->new($username);
        $billings{$username} = $billing;

        my @previous_markers= @{$billing->get_markers()};
        my $last_marker = 0;
        if (@previous_markers) {
            my $last_bill = $previous_markers[-1];
            $last_marker = $last_bill->{marker};
        }
        $last_markers{$username} = $last_marker;

        for my $timestamp ($user->get_timestamps()) {
            unless (exists $user_timestamps{$timestamp}) {
                $user_timestamps{$timestamp} = [ $user ];
            }
            else {
                push $user_timestamps{$timestamp}, $user;
            }
        }
    }

    # 3. load stocks
    # 4. associate timestamps to charges
    my %charges;
    my %charge_timestamps;
    for my $stockname (BeerPlusPlus::Stock->list()) {
        my $stock = BeerPlusPlus::Stock->new($stockname);
        for my $charge ($stock->get_charges()) {
            $charges{$charge} = $charge;

            my $timestamp = $charge->time();
            unless (exists $charge_timestamps{$timestamp}) {
                $charge_timestamps{$timestamp} = [ $charge ];
            }
            else {
                push $charge_timestamps{$timestamp}, $charge;
            }
        }
    }

    # 5. calculate for each timestamp which user consumed from which charge
    my %associations;
    my $charge; # the current charge
    my $bottles = 0;
    for my $timestamp (sort keys %user_timestamps) {
        unless (keys %charge_timestamps) {
            unless ($bottles) {
                warn "running out of timestamps...\n";
                last;
            }
        }

        for my $user (@{$user_timestamps{$timestamp}}) {
            unless (defined $charge and $bottles) {
                my ($next) = sort keys %charge_timestamps;
                unless ($next) {
                    warn "Some beer is missing!\n";
                    last;
                }
                $charge = shift $charge_timestamps{$next};
                unless (@{$charge_timestamps{$next}}) {
                    delete $charge_timestamps{$next};
                    say "deleted \@$next";
                }
                $bottles = $charge->amount();
                $associations{$charge} = {};
            }

            my $username = $user->get_name();
            $associations{$charge}->{$username} = []
                    unless exists $associations{$charge}->{$username};
            push $associations{$charge}->{$username}, $timestamp;
            $bottles--;

            my $t = localtime $timestamp;
            #printf "%s consumed a beer at %s %s from %s\n> bottles=%s\n",
                    #$username, $t->dmy, $t->hms, $charge->stock->get_user,
                    #$bottles;
        }
    }

    # 6. load last markers
    # 7. discard timestamps before markers
    my %calculations;
    for my $charge_key (keys %associations) {
        my $association = $associations{$charge_key};
        for my $username (keys $association) {
            my $last_marker = $last_markers{$username};
            my @relevant_timestamps;
            for my $timestamp (@{$association->{$username}}) {
                if ($timestamp > $last_marker) {
                    push @relevant_timestamps, $timestamp;
                }
            }
            last unless @relevant_timestamps;

            my $charge = $charges{$charge_key};
            my $price = $charge->price();

            my $stock = $charge->stock();
            my $receiver = $stock->get_user();

            $calculations{$username} = {} unless exists $calculations{$username};
            $calculations{$username}->{$receiver} = {}
                    unless exists $calculations{$username}->{$receiver};
            $calculations{$username}->{$receiver}->{$price} = []
                    unless exists $calculations{$username}->{$receiver}->{$price};
            push $calculations{$username}->{$receiver}->{$price},
                    @relevant_timestamps;

            say "$username pays to $receiver " . ($price * @relevant_timestamps);
        }
    }

    #p %calculations;

    # 8. calculate bills
    my %bills;
    for my $username (keys %calculations) {
        my $bill = $billings{$username};

        $bill->{calculation} = $calculations{$username};

        my %payments;
        while (my ($receiver, $consumptions) = each $bill->{calculation}) {
            next if $receiver eq $username;

            my $sum = 0;
            while (my ($price, $timestamps) = each $consumptions) {
                $sum += ($price + $DEPOSIT_BOTTLE) * @{$timestamps};
            }
            $payments{$receiver} = $sum;
        }
        $bill->{payments} = \%payments;

        $bills{$username} = $bill;
    }

    # 11. set markers for currently calculated bills
    while (my ($username, $user) = each %users) {
        my $last_timestamp = ($user->get_timestamps())[-1];
        $billings{$username}->add($last_timestamp);
    }

    return %bills;
}

# steps to do
#
# check all reveivers for each user
# if receiver has also open payment to user
# compare sums
# charge dosen't matters just cash moneyz

#{
    #user2 => 12.32,
    #user3 => 32.42,
#}

# %bill = {
#   user => username,
#   markers => [ <timestamps>+ ],
#   payments => {
#                   <receiver => payoff>+
#               }
# }

sub balance
{
    shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

    my %bills = @_;

    my @garbage;
    for my $username (keys %bills) {
        say "balancing $username...";
        my $bill = $bills{$username};
        my $payments = $bill->{payments};

        for my $receiver (keys $payments) {
#            next unless exists $payments->{$username};

            say "> processing $receiver...";
            my $r_bill = $bills{$receiver};
            my $r_payments = $r_bill->{payments};
            next unless exists $r_payments->{$username};

            say "> found r_payoff:";
            my $payoff = $payments->{$receiver};
            p $payments unless defined $payoff;
            my $r_payoff = $r_payments->{$username};

            if ($payoff > $r_payoff) {
                say "  $payoff > $r_payoff";
                delete $r_payments->{$username};
                p $r_payments->{$username};
                $payments->{$receiver} -= $r_payoff;
                p $payments->{$receiver};
            }
            elsif ($payoff < $r_payoff) {
                say "  $payoff < $r_payoff";
                $r_payments->{$username} -= $payoff;
                delete $payments->{$receiver};
            }
            else {
                say "  $payoff == $r_payoff";
                delete $r_payments->{$username};
                delete $payments->{$receiver};
            }
        }

        unless (keys $payments) {
            say "> removing $username from bills";
            delete $bills{$username};
        }
    }

    return %bills;
}

#
# TODO see debts of one user as single sum and try to distribute it optimally
#      concerning the amount of transactions (handle stock and users separated
#      and balance amount between providing users as last step (?))
#
#   stock1=100€, stock2=50€
#   user1[s1]=20€, user1[s2]=30€, user2[s1]=40€, user3[s1]=40€, user3[s2]=20€
#   -> user1=50€, user2=40€, user3=60€
#   -> user1[s2]=50€, user2[s1]=40€, user3[s1]=60€
#

sub balance_deeply {
    shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

    my %bills = @_;
	for my $username (sort keys %bills) {
		# 1. calculate minimas for each path
		my $paths = balance_recursively(\%bills, $username);
		# 2. find best path by $minima * ($nodes + ($end_node eq $username ? 1 : 0))
		# 3. reckon up
	}

	for my $username (keys %bills) {
		delete $bills{$username} unless keys $bills{$username}->{payments};
	}

	return %bills;
}

sub balance_recursively;
sub balance_recursively {
	my $bills = shift;
	my $username = shift;
	my $marked = shift || {};
	my @payoffs = @_;

	my $indent = "  " x keys $marked;
	say "$indent> processing $username...";

	if (exists $marked->{$username}) {
		say "$indent  found cycle!";
		my $minima = (sort @payoffs)[0];
#		$marked->{$username} += $minima;
		return $minima;
	}

	$marked->{$username} = 0;
	my $bill = $bills->{$username};
	my $payments = $bill->{payments};

	my %paths;
	# TODO sort receivers by highest payoffs
#	while (my ($receiver, $payoff) = each $bill->{payments}) {
	for my $receiver (sort keys $payments) {
		my $payoff = $payments->{$receiver};

		say "$indent  goto $receiver [$payoff]";

		my $path = balance_recursively($bills, $receiver, $marked, @payoffs, $payoff);
		$paths{$receiver} = $path if defined $path;
		# balance debts to receiver by diff

		# check if diffs > caller (?)
		# sum up diffs

#		$marked->{$receiver} += $diff;

#		say "$indent  got diff=$diff";
#		say "$indent  original[$receiver]=", $payments->{$receiver};
#		$payments->{$receiver} -= $diff;
#		say "$indent  balanced[$receiver]=", $payments->{$receiver};
#		delete $payments->{$receiver}
#				if $payments->{$receiver} == 0;
	}

	# check if diffs > caller (?)

	say "$indent  return 0";
	# return summed diffs
	return keys %paths ? \%paths : undef;
}

sub new($$) {
	my $class = shift;
    my $user = shift;

    my $self;
    unless ($DB->exists($user)) {
        $self = {
            user => $user,
            markers => [],
        };
    }
    else {
        $self = $DB->load($user);
    }

	return bless $self, $class;
}

sub get_markers($) {
    my $self = shift;
    return $self->{markers};
}

sub add($$) {
    my $self = shift;
    my $consumption_timestamp = shift;

    my $timestamp = time;
    push $self->{markers}, {
        timestamp => $timestamp,
        marker => $consumption_timestamp
    };
}

sub total
{
    my $self = shift;

    my $total = 0;
    for my $amount (values $self->{payments}) {
        $total += $amount;
    }

    return $total;
}

sub payments
{
    my $self = shift;

    return %{$self->{payments}};
}

sub persist
{
    my $self = shift;
    my $data = {
        user => $self->{user},
        markers => $self->{markers},
    };

    return $DB->store($self->{user}, $data);
}

sub to_string() {
    my $self = shift;

    printf "[%s]\n", $self->{user};

    my $total = 0;
    while (my ($receiver, $amount) = each $self->{payments}) {
        printf "> pay %s cent to %s\n", $amount, $receiver;
        $total += $amount;
    }

    say "> total: $total cent";
}


1;

__END__
