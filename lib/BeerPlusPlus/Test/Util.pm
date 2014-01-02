package BeerPlusPlus::Test::Util;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Test::Util - a module which provides test utilities

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use BeerPlusPlus::Test::Util ':all';

  silent # simply comment this line out to print the messages to STDERR
  {
    # call routines which print warnings and error messages on STDERR
  };

=head1 DESCRIPTION

This module provides some subroutines which eases the testing of the modules
which implement the application's logic/functionality.

=head2 EXPORT

Nothing by default. All subroutines described in section SUBROUTINES can be
imported individually or at once using the export tag C<:all>.

=cut

use parent 'Exporter';

our %EXPORT_TAGS = ( 'all' => [ qw(
	silent
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


=head2 SUBROUTINES

=over 4

=item silent { ... }

This subroutine firstly redirects the STDERR stream temporarily to /dev/null
and then executes the code given in the block. DO NOT forget the semicolon
behind the block (since it's a regular subroutine call)!

=cut

sub silent(&) {
	local *STDERR;
	open STDERR, '>', '/dev/null' or die "cannot open /dev/null: $!";
	shift->();
	close STDERR or warn "cannot close /dev/null: $!";
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

