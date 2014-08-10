package BeerPlusPlus::Billing::Bill;

use strict;
use warnings;

use feature 'say';

use BeerPlusPlus::Stock qw( :vars );

=head1 NAME

BeerPlusPlus::Billing::Bill - data structure for creating bills

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use BeerPlusPlus::Billing::Bill;

=head1 DESCIRPTION

=cut


sub new ($$)
{
    my $class = shift;
    my $calculation = shift;
    my $self = {
        calculations => $calculation,
    };

    return bless $self, $class;
}

sub total
{
    my $self = shift;

    my $sum = 0;
    while (my ($receiver, $consumptions) = each $self->{calculations}) {
        while (my ($price, $timestamps) = each $consumptions) {
            $sum += ($price + $DEPOSIT_BOTTLE) * @{$timestamps};
        }
    }

    return $sum;
}


#
# {
#   "user" : "user1",
#   "bills" : [
#     "<timestamp>" : "<consumption-timestamp>"
#   ]
# }
#
# package BeerPlusPlus::Cache::Bill;
#
# use parent "BeerPlusPlus::Bill";
#

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

