package BeerPlusPlus::Stock;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Stock - module to manage beer++ stocks

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use BeerPlusPlus::Stock;

  $stock = BeerPlusPlus::Stock->new($user);

  $stock->add_crate(time, $price_in_cents);
  ($crate) = $stock->get_crates();

  $time = $crate->{time};
  $price = $crate->{price};

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
		$self->{crates} = [];
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

=item $stock->add_crate($time => $price)

Adds a crate to the stock. The crate is descibed by the time (as Perl's
builtin C<time> returns) and price (in cents) it was bought. Returns
true/1 if the addition was successful, false/0 otherwise.

=cut

sub add_crate($$$) {
	my $self = shift;
	my $time = shift;
	my $price = shift;

	push $self->{crates}, { time => $time, price => $price };

	return $DB->store($self->get_user, $self);
}

=item $stock->get_crates()

Returns a time sorted list of crates which are actually hash-references
with the following structure:

  $crate = {
      time => ...,
      price => ....
  }

=cut

sub get_crates($) {
	my $self = shift;

	return 0 unless @{$self->{crates}};

	# why does sort return undef if crates are empty?
	return sort { $a->{time} <=> $b->{time} } @{$self->{crates}};
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

