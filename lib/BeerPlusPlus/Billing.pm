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

        my @previous_bills = @{$billing->get_bills()};
        my $last_marker = 0;
        if (@previous_bills) {
            my $last_bill = $previous_bills[-1];
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
            printf "%s consumed a beer at %s %s from %s\n> bottles=%s\n",
                    $username, $t->dmy, $t->hms, $charge->stock->get_user,
                    $bottles;
        }
    }

    # 6. load last markers
    # 7. discard timestamps before markers
    my %bills;
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

            my $charge = $charges{$charge_key};
            my $price = $charge->price();

            my $stock = $charge->stock();
            my $receiver = $stock->get_user();

            $bills{$username} = {} unless exists $bills{$username};
            $bills{$username}->{$receiver} = {}
                    unless exists $bills{$username}->{$receiver};
            $bills{$username}->{$receiver}->{$price} = []
                    unless exists $bills{$username}->{$receiver}->{$price};
            push $bills{$username}->{$receiver}->{$price},
                    @relevant_timestamps;

            say "$username pays to $receiver " . ($price * @relevant_timestamps);
        }
    }


    # 8. calculate bills
    p %bills;

    # 11. set markers for currently calculated bills
    while (my ($username, $user) = each %users) {
        my $last_timestamp = ($user->get_timestamps())[-1];
        $billings{$username}->add($last_timestamp);
    }

    return;
}

sub new($$) {
	my $class = shift;
    my $user = shift;

    my $self;
    unless ($DB->exists($user)) {
        $self = { user => $user,
                  bills => [],
                };
    }
    else {
        $self = $DB->load($user);
    }

	return bless $self, $class;
}

sub get_bills($) {
    my $self = shift;
    return $self->{bills};
}

sub add($$) {
    my $self = shift;
    my $consumption_timestamp = shift;

    my $timestamp = time;
    push $self->{bills}, {
        timestamp => $timestamp,
        marker => $consumption_timestamp
    };
}


1;

__END__
