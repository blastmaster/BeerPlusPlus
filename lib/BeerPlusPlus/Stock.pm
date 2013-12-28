package BeerPlusPlus::Stock;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Stock - module to manage beer++ stocks and their charges

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

  use BeerPlusPlus::Stock;

  $stock = BeerPlusPlus::Stock->new($user);

  $username = $stock->get_user();
  $account = $stock->get_account();

  $stock->fill($time, $price, $amount);
  ($charge) = $stock->get_charges();

  $time = $charge->time();
  $price = $charge->price();
  $amount = $charge->amount();

=head1 DESCIRPTION

This module manages the beer++ stocks which are used for the billing.
A stock should be associated to a existent user who provides the beer.

=head2 EXPORT

Nothing by default, but the C<:vars> tag will export the variables
described in section VARIABLES.

=cut

use base 'Exporter';

our %EXPORT_TAGS = ( 'vars' => [ qw(
	$DEPOSIT_BOTTLE $DEPOSIT_CRATE $BOTTLES_PER_CRATE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'vars'} } );


use BeerPlusPlus::Database;


=head2 VARIABLES

=over 4

=item $DEPOSIT_BOTTLE

The deposit of a bottle in cent. Set variable to zero if it should be
ignored for calculation. Defaults to 8.

=cut

our $DEPOSIT_BOTTLE = 8;

=item $DEPOSIT_CRATE

The deposit of a crate in cent. Set variable to zero if it should be
ignored for calculation. Defaults to 150.

=cut

our $DEPOSIT_CRATE = 150;

=item $BOTTLES_PER_CRATE

Specifies how many bottles are contained in one crate. Defaults to 20.

=cut

our $BOTTLES_PER_CRATE = 20;

=back 

=cut


my $DB = BeerPlusPlus::Database->new('stocks');


=head2 CLASS METHODS

=over 4

=item BeerPlusPlus->list()

Returns a list of IDs of all available stocks.

=cut

sub list {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	return $DB->list();
}

=back

=head2 OBJECT METHODS

=over 4

=item BeerPlusPlus->new($username)

Creates a new stock for the given user or loads the associated one.

=cut

sub new($$) {
	my $class = shift;
	my $user = shift;

	my $self = $DB->load($user);
	unless (keys %{$self}) {
		# TODO rename to owner (?)
		$self->{user} = $user;
		$self->{account} = undef;
		$self->{charges} = [];
	}

	return bless $self, $class;
}

=item $stock->get_user()

Returns the user's name.

=cut

sub get_user($) {
	my $self = shift;

	return $self->{user};
}

=item $stock->get_account()

Returns the user's account. See section ACCOUNT for more information on
how to work with the delivered data.

=cut

sub get_account($) {
	my $self = shift;

	return BeerPlusPlus::Stock::Account->new($self->{account});
}

=item $stock->set_account($holder, $number, $code);

Updates the user's account data. Returns true/1 on success; otherwise
false/0.

=cut

sub set_account($$$$) {
	my $self = shift;
	my $holder = shift;
	my $number = shift;
	my $code = shift;

	$self->{account} = {
		holder => $holder,
		number => $number,
		code => $code,
	};

	return $self->persist();
}

=item $stock->fill($time, $price[, $amount])

Adds a charge to the stock. The charge is descibed by the time (as Perl's
builtin C<time> returns) and price (in cents, per bottle) it was bought.
Optionally the amount (which defaults to 20) can be specified. Returns
true/1 if the addition was successful, false/0 otherwise. The charges are
stored in temporal order.

=cut

sub fill($$$;$) {
	my $self = shift;
	my $time = shift;
	my $price = shift;
	my $amount = shift || $BOTTLES_PER_CRATE;

	@{$self->{charges}} = sort { $a->{time} <=> $b->{time} }
			@{$self->{charges}}, {
				time => $time,
				price => $price,
				amount => $amount,
			};

	return $self->persist();
}


=item $stock->get_charges()

Returns a time sorted list of charges which are actually objects of the
C<BeerPlusPlus::Stock::Charge> package (see section CHARGE below).

=cut

sub get_charges($) {
	my $self = shift;

	my @charges = @{$self->{charges}};

	return map { BeerPlusPlus::Stock::Charge->new($_, $self) } @charges;
}

=item $stock->persist()

Persists the current state of the stock-object. Returns true/1 if the object
was stored successfully; otherwise false/0.

=cut

sub persist($) {
	my $self = shift;

	return $DB->store($self->get_user, $self);
}

=back

=cut


=head1 ACCOUNT

The C<BeerPlusPlus::Stock::Account> package provides convenient access to
the user's account data. The account is used for the billing.

=cut

package BeerPlusPlus::Stock::Account;

=head2 METHODS

=over 4

=item BeerPlusPlus::Stock::Account->new({ holder => $h, number => $n, code => $c })

Creates a new account-object with the given data. If no data is given C<undef>
is returned. This constructor is intended for internal use only.

=cut

sub new($$) {
	my $class = shift;
	my $data = shift;

	return undef unless $data;

	my $self = {
		holder => $data->{holder},
		number => $data->{number},
		code => $data->{code},
	};

	return bless $self, $class;
}

=item $account->holder();

Returns the name of the account's holder or owner, respectively.

=cut

sub holder($) {
	my $self = shift;

	return $self->{holder};
}

=item $account->number();

Returns the account number.

=cut

sub number($) {
	my $self = shift;

	return $self->{number};
}

=item $account->code();

Returns the code of the bank the account belongs to.

=cut

sub code($) {
	my $self = shift;

	return $self->{code};
}

=item $account->to_string();

Generates an appropriate text representation of the account.

=cut

sub to_string() {
	my $self = shift;

	return sprintf "Account\n-------\nHolder: %s\nNumber: %s\nCode:   %s",
			$self->holder(), $self->number(), $self->code();
}

=back

=cut


=head1 CHARGE

The C<BeerPlusPlus::Stock::Charge> package encapsulates a filled in charge
and thus is specified by time, price and amount. It also provides some
convenience routines.

=cut

package BeerPlusPlus::Stock::Charge;

=head2 METHODS

=over 4

=item BeerPlusPlus::Stock::Charge->new({ time => $t, price => $p, amount => $a})

Creates a new charge-object with the specified data. This constructor is
intended for internal use only.

=cut

sub new($$) {
	my $class = shift;
	my $data = shift;
	my $stock = shift;

	my $self = {
		time => $data->{time},
		price => $data->{price},
		amount => $data->{amount},
		stock => $stock,
	};

	return bless $self, $class;
}

=item $charge->time()

Returns the time the charge was added to the stock.

=cut

sub time($) {
	my $self = shift;

	return $self->{time};
}

=item $charge->price()

Returns the price per bottle of the charge.

=cut

sub price($) {
	my $self = shift;

	return $self->{price};
}

=item $charge->amount()

Returns the amount of bottles of the charge.

=cut

sub amount($) {
	my $self = shift;

	return $self->{amount};
}

=item $charge->stock()

Returns the stock the charge belongs to.

=cut

sub stock($) {
	my $self = shift;

	return $self->{stock};
}

=item $charge->date([$format, @fields])

Returns the time of the charge as formatted date/time. The first argument is
the format while the following list defines the fields and order of Perl's
builtin C<localtime> (only the fields from C<0> to C<5> can be used). By
default the format is C<%02d.%02d.%d> using the list C<3 .. 5> which results
in C<DD.MM.YYYY>. To produce a string equals to C<YYYY-MM-DD HH:mm:ss> just
specify

  $charge->date("%d-%02d-%02d %02d:%02d:%02d", reverse 0 .. 5)

See L<perldoc/localtime> and L<perldoc/sprintf> for more information.

=cut

sub date($;$@) {
	my $self = shift;
	my $format = shift || "%02d.%02d.%d";
	my @fields = @_  ? @_ : 3 .. 5;

	my ($sec, $min, $hour, $day, $mon, $year) = localtime $self->time;
	$year += 1900;
	$mon += 1;

	return sprintf $format, ($sec, $min, $hour, $day, $mon, $year)[@fields];
}

=item $charge->bottles()

Returns a list of bottles of the charge which is in fact the price per bottle
times the charge's amount. The price is calculated as follows:

  $price + $DEPOSIT_BOTTLE

Thus by changing the value of the deposit variable changes the result. To
ignore the deposit for calculation simply set the variable to zero. This
method is provided for convenience.

=cut

sub bottles($) {
	my $self = shift;

	return ($self->price + $DEPOSIT_BOTTLE) x $self->amount;
}

=item $charge->to_string()

Returns a string representation of the charge consisted of the date/time, the
amount (crates/bottles) and some calculated prices (total and bottle price).

=cut

sub to_string($) {
	my $self = shift;

	my $price = $self->price;
	my $total = $price * $self->amount;

	return sprintf "[%s] %d crates + %d bottles = %d.%02d€ (%d.%02d€/bottle)",
			$self->date,
			$self->amount / $BOTTLES_PER_CRATE,
			$self->amount % $BOTTLES_PER_CRATE,
			$total / 100, $total % 100, $price / 100, $price % 100;
}

=back

=cut


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

