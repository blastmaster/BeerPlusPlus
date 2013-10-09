package BeerPlusPlus::Login;
use Mojo::Base 'Mojolicious::Controller';

use Digest::SHA qw(sha1_base64);
use feature "say";

sub index
{
	my $self = shift;
	my $user = $self->param('user') || '';
	# FIXME http://onkeypress.blogspot.de/2011/07/perl-wide-character-in-subroutine-entry.html
	my $pass = sha1_base64($self->param('pass')) || '';
	$self->session(user => $user);
	$self->session(pass => $pass);
	$self->redirect_to('/welcome');
}

sub auth
{
	my $self = shift;
	my $user = $self->session->{user};
	return 1 if $self->session->{pass} eq $self->session->{expected_pass};
}

sub logout
{
	my $self = shift;
	$self->persist;
	delete $self->session->{expected_pass};
	%{ $self->session } = ();
	$self->session(expires => 1);
	my @byebyes = ('kree sha', 'lek tol');
	my $byebye = $byebyes[rand @byebyes];
	$self->render('logout', byebye => $byebye, subtitle => $byebye);
}

1;
