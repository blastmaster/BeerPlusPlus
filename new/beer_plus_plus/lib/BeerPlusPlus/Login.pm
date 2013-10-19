package BeerPlusPlus::Login;
use Mojo::Base 'Mojolicious::Controller';

use Digest::SHA qw(sha1_base64);
use feature "say";
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
	my $pass = sha1_base64($self->param('pass')) || '';
	$self->session(user => $username);
	$self->session(pass => $pass);
	my $hash = $self->user->init($username);
	$self->session(expected_pass => $hash->{pass});
	p $hash;
	# $self->res->headers->cache_control('max-age=1, no_cache');
	# $self->render(controller => 'user', action => 'init');
	 $self->redirect_to('/welcome');
}

sub is_auth
{
	my $self = shift;
	p $self->session;
	return 1 if $self->session->{user} && $self->session->{pass} eq $self->session->{expected_pass};
	return $self->redirect_to('/welcome');
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
