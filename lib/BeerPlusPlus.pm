package BeerPlusPlus;

use strict;
use warnings;

use feature 'say';


use Mojo::Base 'Mojolicious';

use Carp;

use BeerPlusPlus::Plugin;
use BeerPlusPlus::User;

use Data::Printer;


my $LOG = Mojo::Log->new();
my %reg_pages;


# This method will run once at server start
sub startup {
	my $self = shift;

	# TODO check for current structure and die if old one found

	# Documentation browser under "/perldoc"
	# $self->plugin('PODRenderer');

	# create user object
	$self->helper(user => sub { BeerPlusPlus::User->new(shift->session->{user}) });
	$self->helper(uman => sub { 'BeerPlusPlus::User' }); # for "static" method calls

	$self->helper(footer => \&footer);

	$self->helper(log => sub { $LOG });


	# Router
	my $r = $self->routes;

	$r->any('/')->to('login#login');
    $r->get('/index')->to('login#login');
	$r->post('/login')->to('login#index');
	$r->get('/logout')->to('login#logout');

	$r = $r->under->to('login#is_auth');
	# FIXME redirect to login if session is lost (e.g. after restart)
#	$r = $r->under(sub {
#			$self->redirect_to('/index') unless $self->{user};
#	});

    $r->post('/increment')->to('login#plusplus');
    $r->post('/register')->to('login#register');

	$r->get('/chpw' => sub { shift->render('register'); });

	$r->get('/welcome' => sub {
			my $self = shift;

			my $user = $self->user;
			$self->stash(user => $user->get_name());
			$self->stash(count => $user->get_count());
			$self->render(template => 'welcome', format => 'html');
		});

	$r->get('/denied' => sub {
		my $self = shift;
		$self->render(controller => 'denied', subtitle => "rin'tel'noc");
	});

	%reg_pages = $self->initialize_plugins();
}

sub footer {
    my $self = shift;
	my $spec = shift;

	if (defined $spec and $spec eq 'only_login') {
		my $login = $self->link_to(login => '/');
		return Mojo::ByteStream->new(<<HTML);
<div id="footer">
	<span style="float: right">$login |</span>
</div>
HTML
	}

	my %pages = (
		%reg_pages,
		'/welcome' => 'home',
		'/chpw' => 'change password',
		'/rules.pdf' => 'rules'
	);
	my $current = $self->url_for('current');

	my @links;
	for my $path (keys %pages) {
		next if $path eq $current;
		push @links, $self->link_to($pages{$path} => $path);
	}

	my $links = join " |\n", @links;
	my $logout = $self->link_to(logout => '/logout');
	return Mojo::ByteStream->new(<<HTML);
<div id="footer">
	<span style="float: left">
		$links
	</span>
	<span style="float: right">$logout |</span>
</div>
HTML
}


1;
