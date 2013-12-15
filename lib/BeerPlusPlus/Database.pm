package BeerPlusPlus::Database;

use strict;
use warnings;

use feature 'say';


use Carp;
use File::Path 'make_path';
use Mojo::JSON 'j';


=head1 NAME

BeerPlusPlus::Database - interface to the persistance layer of beer++

=head1 DESCRIPTION

  db
  |
  +-{store-id}
    |
    +-{data-id}.json

=cut


our $DATADIR = 'db';


sub new($$) {
	my $class = shift;
	my $store_id = shift;

	my $self = {
		base => "$DATADIR/$store_id",
	};

	return bless $self, $class;
}

sub exists($$) {
	my $self = shift;
	my $data_id = shift;

	return -f $self->fullpath($data_id);
}

sub fullpath($$) {
	my $self = shift;
	my $data_id = shift;

	return $self->{base} . "/$data_id.json";
}

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
		return j($data);
	}
}

sub store($$$) {
	my $self = shift;
	my $data_id = shift;
	my $hash = shift;

	unless (-d $self->{base}) {
		make_path($self->{base}) or croak("cannot create " . $self->{base});
	}
	my $path = $self->fullpath($data_id);
	
	unless (open FILE, '>', $path) {
		carp "cannot open $path: $!";
		return 0;
	} else {
		my $data = j($hash);
		print FILE $data;
		close FILE or carp "cannot close $path: $!";
		return 1;
	}
}


1;

