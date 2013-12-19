package BeerPlusPlus::User;

use strict;
use warnings;

use feature 'say';


use BeerPlusPlus::Database;

use Cwd 'abs_path';
use Digest::SHA qw(sha1_base64);
use File::Basename;
use Mojo::JSON;
use Carp;

use Data::Printer;


my $DEFAULT_PASSWORD = 'lukeichbindeinvater';
my $DB = BeerPlusPlus::Database->new('users');


sub hash($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $password = shift;

	return sha1_base64($password);
}

sub create($$) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $name = shift;
	my $password = hash(shift || $DEFAULT_PASSWORD);

	if ($DB->exists($name)) {
		say STDERR "warn: user '$name' already exists!";
		return 0;
	}

	my $user = {
		user => $name,
		pass => $password,
		times => [],
		payoffset => 0,
	};

	return $DB->store($name, $user);
}

sub list() {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	return $DB->list();
}

sub exists($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $name = shift;
	
	return $DB->exists($name);
}

sub new($) {
	my $class = shift;
	my $user = shift or carp("undefined username");

	return undef unless $DB->exists($user);

	my $self = $DB->load($user);

	return bless $self, $class;
}

sub get_name($) {
	my $self = shift;

	return $self->{user};
}

sub verify($$) {
	my $self = shift;
	my $password = shift;

	return $password eq $self->{pass};
}

sub get_count($) {
	my $self = shift;

	return scalar $self->get_timestamps();
}

sub get_timestamps($) {
	my $self = shift;

	# NOTE this is just a check for older versions
	return undef unless defined $self->{times};

	return @{$self->{times}};
}

sub increment($) {
    my $self = shift;

	push $self->{times}, time;
	$self->persist();

	return $self->get_count();
}

sub change_password($$) {
	my $self = shift;
	my $newpw = shift;

	# TODO may verify with old password before changing (?)

	$self->{pass} = $newpw;

	return $self->persist();
}

sub get_payoffset($) {
	my $self = shift;

	return $self->{payoffset};
}

sub set_payoffset($$) {
	my $self = shift;
	my $offset = shift;

	$self->{payoffset} = $offset;
}

sub persist($) {
	my $self = shift;

	return $DB->store($self->{user}, $self);
}

sub list_others($) {
	my $self = shift;
	
	return grep { not $_ eq $self->{user} } $self->list();
}

sub get_others($) {
	my $self = shift;

	return map { __PACKAGE__->new($_) } $self->list_others();
}


1;

