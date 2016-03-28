package BeerPlusPlus;

use strict;
use warnings;

use feature 'say';


use Mojo::Base 'Mojolicious';

use Carp;

use BeerPlusPlus::Plugin;
use BeerPlusPlus::User;

use Data::Printer;

use Time::Piece;
use Time::Seconds;


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

	$r->post('/increment')->to('login#plusplus');
	$r->post('/register')->to('login#register');

	$r->get('/chpw' => sub { shift->render('register'); });

	$r->get('/welcome' => sub {
			my $self = shift;

			my $user = $self->user;
			$self->stash(user => $user->get_name());
			$self->stash(count => $user->get_count());
			$self->stash(last => get_last_plusplus($user));
			$self->render(template => 'welcome', format => 'html');
	});

	$r->get('/denied' => sub {
			my $self = shift;
			$self->render(controller => 'denied', subtitle => "rin'tel'noc");
	});

	%reg_pages = $self->initialize_plugins();
}

sub get_last_plusplus {
	my $user = shift;

	my @timestamps = $user->get_timestamps();
	my $ts = localtime (@timestamps ? $timestamps[-1] : 0);
	my $now = localtime;

	my $last;
	if ($ts->dmy eq $now->dmy or $ts+3*ONE_HOUR > $now) {
		$last = $ts->strftime('at %H:%M');
	} elsif (($ts+ONE_DAY)->dmy() eq $now->dmy()) {
		$last = $ts->strftime('yesterday, %H:%M');
	} elsif ((my $diff = $now - $ts) <= 3*ONE_DAY) {
		$last = sprintf '%d days ago, %s', $diff->days, $ts->strftime('%H:%M');
	} elsif ($ts->year == $now->year) {
		$last = $ts->strftime('on %d.%m., %H:%M');
	} else {
		$last = $ts->strftime('on %d.%m.%Y, %H:%M');
	}

	return $last;
}

sub create_footer_link($$$) {
	my $self = shift;
	my $link = shift;
	my $target = shift;

	my $current = $self->url_for('current');
	$target .= '#' if $current eq $target;

	return $self->link_to($link => $target)
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
		'/chpw' => 'change password',
		'/rules.pdf' => 'rules'
	);

	my @links = ( create_footer_link($self, 'home' => '/welcome') );
	for my $path (sort keys %pages) {
		push @links, create_footer_link($self, $pages{$path} => $path);
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
