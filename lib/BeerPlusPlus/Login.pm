package BeerPlusPlus::Login;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;

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
    my $log = Mojo::Log->new;
	my $username = $self->param('user') || '';
	# FIXME http://onkeypress.blogspot.de/2011/07/perl-wide-character-in-subroutine-entry.html
	my $pass = sha1_base64($self->param('pass')) || '';
	my $userhash = $self->user->init($username);
    unless ( $userhash ) {
        $log->debug("userhash is undef ... redirect");
        $self->redirect_to('/index');
        return 0;
    }
    my $counter = 0;
    if (@{$userhash->{times}}) {
        $counter = @{$userhash->{times}};
    }
    else {
        die "you may work with old userfile structure";
    }
	$self->res->headers->cache_control('max-age=1, no_cache');
	$self->session(user => $username);
	$self->session(pass => $pass);
	$self->session(expected_pass => $userhash->{pass});
	$self->session(counter => $counter);
	$self->redirect_to('/welcome');
}

sub plusplus
{
    my $self = shift;
    my $newcount = 0;
    $newcount = $self->user->increment();
    $self->session->{counter} = $newcount;
    $self->redirect_to('/welcome');
}

sub is_auth
{
	my $self = shift;
	return 1 if $self->session->{user} && $self->session->{pass} eq $self->session->{expected_pass};
	return $self->redirect_to('/index');
}

sub register
{
	my $self = shift;
    if ($self->req->method eq 'GET') {
        $self->render('register');
    }
    elsif ($self->req->method eq 'POST') {
        if ($self->param('passwd') ne $self->param('passwd2')) {
            $self->render('register');
            return 0;
        }
        $self->check($self->param('passwd'), $self->param('passwd2'));
        my $newpw = sha1_base64($self->param('passwd'));
        $self->session->{pass} = $newpw;
        $self->session->{expected_pass} = $newpw;
        $self->user->set_attribute(pass => $newpw);
        $self->user->persist();
        $self->redirect_to('/welcome');
    }
    return 1;
}

sub check
{
	my $self = shift;
	my $newpw = shift;
	$self->render(text => qq/come on .../) if (length($newpw) < 8);
	return 0;
}

sub logout
{
	my $self = shift;
	$self->user->persist();
	%{ $self->session } = ();
	$self->session(expires => 1);
	my @byebyes = ('kree sha', 'lek tol');
	my $byebye = $byebyes[rand @byebyes];
	$self->render('logout', byebye => $byebye, subtitle => $byebye);
}

1;
