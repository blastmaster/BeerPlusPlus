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
	my $userhash = $self->user->init($username);
	$self->res->headers->cache_control('max-age=1, no_cache');
	$self->session(user => $username);
	$self->session(pass => $pass);
	$self->session(expected_pass => $userhash->{pass});
	$self->session(counter => $userhash->{counter});
	$self->redirect_to('/welcome');
}

sub is_auth
{
	my $self = shift;
	p $self->session;
	return 1 if $self->session->{user} && $self->session->{pass} eq $self->session->{expected_pass};
	return $self->redirect_to('/index');
}

sub logout
{
	my $self = shift;
    my $counter = $self->session->{counter};
	$self->user->persist($counter);
	delete $self->session->{expected_pass};
	%{ $self->session } = ();
	$self->session(expires => 1);
	my @byebyes = ('kree sha', 'lek tol');
	my $byebye = $byebyes[rand @byebyes];
	$self->render('logout', byebye => $byebye, subtitle => $byebye);
}

1;