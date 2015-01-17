package BeerPlusPlus::User;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::User - module for managing beer++ users

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

  use BeerPlusPlus::User;

  BeerPlusPlus::User->create($name) or die "couldn't create user $name";
  BeerPlusPlus::User->exists($name) or warn "user $name does not exist";

  @usernames = BeerPlusPlus::User->list();
  for my $name (@usernames) {
      my $user = BeerPlusPlus::User->new($name);

      $user->get_name() eq $name or die "...";
      my $email = $user->get_email();

      $user->consume();

      my $count = $user->get_count();
      my @timestamps = $user->get_timestamps();
  }

=head1 DESCRIPTION

The user module is intended to serve both as management unit and as data
structure. The usual life cycle is as follows: First the new is added to
the system using the class' C<create> method. Then over time the score is
incremented as the user C<consume>s beer. Since the main purpose of the
whole application is a automatic billing system the consumed beer are
accounted periodically. To avoid the loss of statistically interesting
data the count is not resetted. Instead a pay offset is introduced which
indicates which amount the user has already paid. Thus the offset must be
updated after each billing.

=cut


use BeerPlusPlus::Database;

use Cwd 'abs_path';
use Digest::SHA qw(sha1_base64);
use File::Basename;
use Mojo::JSON;
use Carp;

use Data::Printer;


my $DEFAULT_PASSWORD = 'lukeichbindeinvater';
my $DB = BeerPlusPlus::Database->new('users');


=head2 CLASS METHODS

The class methods can be accessed both as object and as package/string:

  $self-><method>(...)
  BeerPlusPlus::User-><method>(...)
  BeerPlusPlus::User::<method>(...)

=over 4

=item BeerPlusPlus::User->hash($password)

Hashes the given password and returns the Base 64 encoded result.

=cut

sub hash($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $password = shift;

	return sha1_base64($password);
}

=item BeerPlusPlus::User->create($user, $password)

Creates a new user if it does not exist. Returns true/1 if the user was
created successfully; false/0 otherwise, e.g. if the user exists or couldn't
be stored successfully.

=cut

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
		email => undef,
		times => [],
		payoffset => 0,
	};

	return $DB->store($name, $user);
}

=item BeerPlusPlus::User->list()

Lists all existent users and returns the list of all names.

=cut

sub list() {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;

	return $DB->list();
}

=item BeerPlusPlus::User->exists($username)

Returns true/1 if the user exists already; otherwise false/0.

=cut

sub exists($) {
	shift if $_[0] eq __PACKAGE__ or ref $_[0] eq __PACKAGE__;
	my $name = shift;
	
	return $DB->exists($name);
}

=back

=head2 OBJECT METHODS

=over 4

=item BeerPlusPlus::User->new($username)

Creates a new user object with the specified username. Returns undef if the
user does not exist already.

=cut

sub new($) {
	my $class = shift;
	my $user = shift or carp("undefined username");

	return undef unless $DB->exists($user);

	my $self = $DB->load($user);

	return bless $self, $class;
}

=item $user->get_name()

Returns the name of the user.

=cut

sub get_name($) {
	my $self = shift;

	return $self->{user};
}

=item $user->verify($hashed_password)

Returns true/1 if the given password is equals the users password. The given
password must be hashed with the module's C<hash> method before.

=cut

sub verify($$) {
	my $self = shift;
	my $password = shift;

	return $password eq $self->{pass};
}

=item $user->get_count()

Returns the count which is actually the number of timestamps.

=cut

sub get_count($) {
	my $self = shift;

	return scalar $self->get_timestamps();
}

=item $user->get_timestamps()

Returns the list of timestamps.

=cut

sub get_timestamps($) {
	my $self = shift;

	# NOTE this is just a check for older versions
	return undef unless defined $self->{times};

	return @{$self->{times}};
}

=item $user->consume([$time])

Increments the user's count by one by adding the current timestamp. The
updated count is returned. Optionally the time can be specified as argument.
The timestamps are always inserted and persisted ordered by time.

=cut

sub consume($;$) {
    my $self = shift;
	my $time = shift || time;

	push @{$self->{times}}, $time;
	@{$self->{times}} = sort @{$self->{times}};
	$self->persist();

	return $self->get_count();
}

=item $user->change_password($new_password)

Changes the user's password by updating the internal and external data.
Returns true/1 on success; otherwise false/0.

=cut

sub change_password($$) {
	my $self = shift;
	my $newpw = shift;

	# TODO may verify with old password before changing (?)

	$self->{pass} = $newpw;

	return $self->persist();
}

=item $user->get_email()

Returns the email address of the user.

=cut

sub get_email($) {
	my $self = shift;

	return $self->{email};
}

=item $user->set_email($email)

Updates the email address with the given one. Returns true/1 on success;
otherwise false/0.

=cut

sub set_email($$) {
	my $self = shift;
	my $email = shift;

	$self->{email} = $email;

	return $self->persist();
}

=item $user->get_payoffset()

Returns the pay offset which indicates how many beer were already paid.

=cut

sub get_payoffset($) {
	my $self = shift;

	return $self->{payoffset};
}

=item $user->set_payoffset($offset)

Updates the pay offset with the given one.

=cut

sub set_payoffset($$) {
	my $self = shift;
	my $offset = shift;

	$self->{payoffset} = $offset;
}

=item $user->persist()

Persists the state of the user object.

=cut

sub persist($) {
	my $self = shift;

	return $DB->store($self->{user}, $self);
}

=item $user->list_others()

Returns a list of names of the other users (i.e. excluding the current one).

=cut

sub list_others($) {
	my $self = shift;
	
	return grep { not $_ eq $self->{user} } $self->list();
}

=item $user->get_others()

Returns a list of user objects of all users except the current one.

=cut

sub get_others($) {
	my $self = shift;

	return map { __PACKAGE__->new($_) } $self->list_others();
}

=back

=cut


1;

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

Blastmaster, E<lt>blastmaster@tuxcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Innercircle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

