package BeerPlusPlus::Plugin;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Plugin - module which enables plugin support for modules of
namespace C<BeerPlusPlus::Plugin::>

=head1 SYNOPSIS

In the module which want to use the plugins:

  use BeerPlusPlus::Plugin;

  # ... and later
  $self->initialize_plugins(@params);

A plugin module:

  package BeerPlusPlus::Plugin::Example;

  sub initialize { # or whatever the the init-subroutine is named (see OPTIONS)
      my $self = shift;

      # initialize the plugin, add routes etc., e.g.
      $self->routes->get('/example' => sub { ... });

      return '/example' => 'example-link'
  }

=head1 DESCRIPTION

Using this module adds a subroutine C<initialize_plugins> into the namespace
of the caller. To initialize the plugins this method has to be called from
within the C<startup> method of the Mojolicious application. The return value
of that subroutine is a hash which consists of path-linkname pairs.

Any plugin must implement a subroutine whose name is specified by the OPTION
C<sub> (defaults to C<initialize>). Within that subroutine the plugin should
do its initialization and registration to the Mojolicious application. The
return value should be a mapping C<$path => $linkname> which will later be
translated into links to the plugin's page. If this is not a page-plugin an
empty array should be returned. B<NOTE:> If the plugin does not implement such
a subroutine it is silently skipped.

=head2 EXPORT

None but adds a new subroutine. See C<import> below.

=cut


use Module::Pluggable require => 1, search_path => __PACKAGE__;


=head2 OPTIONS

=over 4

=item sub

use the associated value as name for the added/exported subroutine (defaults
to C<initialize_plugins>)

=item init

use the associated value as name of the subroutine called to initialize the
plugin (defaults to C<initialize>)

=back

=head2 SUBROUTINES

=over 4

=item import

Adds the subroutine mentioned above into the callers namespace.

=cut

sub import {
	my $class = shift;
	my %opts = @_;

	my $pkg = caller;
	my $sub = $opts{sub} || 'initialize_plugins';
	my $init = $opts{init} || 'initialize';
	
	no strict 'refs';
	*{"$pkg\::$sub"} = sub {
		return map { $_->can($init) ? &{"$_\::$init"}(@_) : () } plugins();
	};
	use strict 'refs';
}

=back

=cut


1;
__END__

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

