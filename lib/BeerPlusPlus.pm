package BeerPlusPlus;
use Mojo::Base 'Mojolicious';

use BeerPlusPlus::User;

use Data::Printer;
use feature "say";


use BeerPlusPlus::Plugin;


my $DATADIR = 'users';
my %reg_pages;

# This method will run once at server start
sub startup {
	my $self = shift;

	# TODO check for current structure and die if old one found

	# Documentation browser under "/perldoc"
	# $self->plugin('PODRenderer');

	# create user object
	$self->helper(user => sub { state $user = BeerPlusPlus::User->new($DATADIR) });

	$self->helper(footer => \&footer);

	# Router
	my $r = $self->routes;


	$r->any('/')->to('login#login');

    $r->get('/index')->to('login#login');

	$r->post('/login')->to('login#index');

	$r->get('/logout')->to('login#logout');

	$r = $r->under->to('login#is_auth');

	$r->get('/welcome' => sub { shift->render(template => 'welcome', format => 'html'); });

    $r->post('/increment')->to('login#plusplus');

	$r->get('/chpw' => sub { shift->render('register'); });

    $r->route('/register')->via('GET', 'POST')->to('login#register');

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
