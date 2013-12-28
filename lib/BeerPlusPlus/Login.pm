package BeerPlusPlus::Login;

use strict;
use warnings;

use feature 'say';


use Mojo::Base 'Mojolicious::Controller';

use Data::Printer;


sub login
{
	my $self = shift;

	$self->render(template => 'index', format => 'html');
}

sub index
{
	my $self = shift;

	my $username = $self->param('user') || '';
	# FIXME http://onkeypress.blogspot.de/2011/07/perl-wide-character-in-subroutine-entry.html
	my $password = $self->uman->hash($self->param('pass'));

	unless ($self->uman->exists($username)) {
		$self->log->error("user '$username' does not exist");
		# TODO display message in browser!
		return $self->render('denied', subtitle => "rin'tel'noc");
	}

	$self->res->headers->cache_control('max-age=1, no_cache');
	$self->session(user => $username);
	$self->session(pass => $password);

	$self->redirect_to('/welcome');
}

sub plusplus
{
    my $self = shift;

	$self->user->increment();
    $self->redirect_to('/welcome');
}

sub is_auth
{
	my $self = shift;

	return 1 if $self->user->verify($self->session->{pass});
	return $self->redirect_to('/index');
}

sub register
{
	my $self = shift;

	my $password = $self->param('passwd');
	my $repetition = $self->param('passwd2');

	return $self->render('register')
			unless $self->check($password, $repetition);
	
	my $newpw = $self->uman->hash($password);
	$self->user->change_password($newpw)
			or $self->log->error("change password failed");
	$self->session->{pass} = $newpw;

	$self->redirect_to('/welcome');
}

sub check
{
	my $self = shift;
	my $password = shift;
	my $repetition = shift;

	return $password eq $repetition and length $password >= 8;
}

sub logout
{
	my $self = shift;

	%{ $self->session } = ();
	$self->session(expires => 1);
	my @byebyes = ('kree sha', 'lek tol');
	my $byebye = $byebyes[rand @byebyes];
	$self->render('logout', byebye => $byebye, subtitle => $byebye);
}

1;
