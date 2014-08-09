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


1;

__END__
