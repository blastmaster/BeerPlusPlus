package BeerPlusPlus::Database;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Database - interface to the persistance layer of beer++

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

  use BeerPlusPlus::Database;

  $db = BeerPlusPlus::Database->new('store_id');
  $db->exist('data_id') or warn "db-entry 'data_id' does not exist";
  $db->store(data_id => \%data) or warn "cannot store db-entry 'data_id'";
  $data = $db->load('data_id') or warn "cannot load db-entry 'data_id'";
  $db->remove('data_id') or warn "cannot remove db-entry 'data_id': $!";

  # empty database
  $db->remove($_) for $db->list();

=head1 DESCRIPTION

The database module encapsulates the persistence layer from the application
logic by providing an interface for loading and storing data. Hence the way
the data is stored (and loaded) can be exchanged without affecting the usage
of the database module.

For now the database implementation is file-based which leads to following
directory structure:

  db
  +---{store_id}
      +---{data_id}.json

The database' root directory (in this case C<db> which is also the default
value) is given through the C<$DATADIR> variable (see section VARIABLES).
The database is divided into stores which separates module specific data
from each other. Within these stores each datum indicated through an unique
ID is persisted in a separate file. Due to the encoding of the file as JSON
each possible hash-array-scalar combination can be stored.

=cut


use Carp;
use File::Path 'make_path';
#use Mojo::JSON 'j';
use JSON::PP;
use Scalar::Util qw(blessed reftype);


=head2 VARIABLES

=over 4

=item DATADIR

This variable hold the path to the root directory of the database. Within this
directory all stores are located which in turn contain the data.

=cut

our $DATADIR = 'db';

=item JSON

An instance of JSON::PP which defaults to print pretty formatted JSON.

=back

=cut

our $JSON = JSON::PP->new->pretty(1);


=head2 METHODs

=over 4

=item BeerPlusPlus::Database->new($store_id)

Creates a new database with the given store-ID. Besides it will create the
directory structure as necessary and might die if the directories cannot be
created successfully.

=cut

sub new($$) {
	my $class = shift;
	my $store_id = shift;

	my $base = "$DATADIR/$store_id";
	my $self = {
		base => $base,
		init => -d $base || 0,
	};

	carp("database '$store_id' not initialized") unless $self->{init};

	return bless $self, $class;
}

=item $db->exists($data_id)

Returns true/1 if the given data-ID does exist in the database; false/0
otherwise.

=cut

sub exists($$) {
	my $self = shift;
	my $data_id = shift;

	return $self->{init} && -f $self->fullpath($data_id);
}

=item $db->fullpath($data_id)

Returns the full (but not necessarily absolute path) to the db-file which
contains the data.

B<NOTE:> This method should NOT be used since it is intened for internal
use only and might be removed in future versions, i.e. if this module is
transformed into an interface.

=cut

sub fullpath($$) {
	my $self = shift;
	my $data_id = shift;

	return $self->{base} . "/$data_id.json";
}

=item $db->list()

Returns a list of all existent data-IDs.

=cut

sub list($) {
	my $self = shift;

	return () unless $self->{init};
	return grep { s/(.*\/|\.json$)//g } glob $self->{base} . '/*.json';
}

=item $db->load($data_id)

Returns the hash-reference which is associated to the data-ID. The referenced
hash is empty if no entry is associated to the given data-ID (according to the
C<exists> method) or if an empty hash was stored previously.

=cut

sub load($$) {
	my $self = shift;
	my $data_id = shift;

	return {} unless $self->exists($data_id);

	my $path = $self->fullpath($data_id);

	unless (open FILE, '<', $path) {
		carp "cannot open $path: $!";
		return undef;
	} else {
		my $data = join "", <FILE>;
		close FILE or carp "cannot close $path: $!";
		return $data ? $JSON->decode($data) : {};
	}
}

=item $db->store($data_id, $data_hash)

Stores the the given hash-reference associated to the data-ID. If the given
reference is a blessed C<HASH> reference it will be converted to an unblessed
one before storing. Returns true/1 on success; false/0 otherwise.

=cut

sub store($$$) {
	my $self = shift;
	my $data_id = shift;
	my $hash = shift;

	unless (defined $hash) {
		carp "undefined hash-reference";
		return 0;
	} elsif (ref $hash ne 'HASH') {
		if (blessed $hash and reftype $hash eq 'HASH') {
			$hash = { %{$hash} };
		} else {
			carp "not a [blessed] hash-reference: $hash";
			return 0;
		}
	}


	make_path($self->{base}, { mode => 0755 }) and $self->{init} = 1
			unless $self->{init};

	my $path = $self->fullpath($data_id);
	
	unless (open FILE, '>', $path) {
		carp "cannot open $path: $!";
		return 0;
	} else {
		print FILE $JSON->encode($hash);
		close FILE or carp "cannot close $path: $!";
		return 1;
	}
}

=item $db->remove($data_id) or warn "cannot remove $data_id: $!"

Removes the entry associated to the given data-ID. Returns true/1 on success;
false/0 otherwise while C<$!> will be set I<except> the data-ID does not exist
in which case C<undef> will be returned.

=cut

sub remove($$) {
	my $self = shift;
	my $data_id = shift;

	return undef unless $self->exists($data_id);

	return unlink $self->fullpath($data_id);
}

=back

=cut


1;
__END__

=head1 IDEAS / TODOs / FUTURE PLANS

=over 4

=item * enable support for extending classes

  use BeerPlusPlus::Database 'store_id';

  $DB->...

OR

  use parent 'BeerPlusPlus::Database';

  our $STORE_ID = '...';

  sub read {
      my $self = shift;
      # modify internal data...
      $self->load($data_id);
  }

  sub write {
      my $self = shift;
      # modify internal data...
      $self->store($data_id);
  }

=back

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Innercircle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

