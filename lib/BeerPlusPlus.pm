package BeerPlusPlus;

use strict;
use warnings;

use feature 'say';


use Mojo::Base 'Mojolicious';

use Carp;

use BeerPlusPlus::Plugin;
use BeerPlusPlus::User;
use BeerPlusPlus::Util::Format;

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

	return "" unless @timestamps;
	return sprintf "Last ++ %s", get_elapsed_in_words($timestamps[-1], time);
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
