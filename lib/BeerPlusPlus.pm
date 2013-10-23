package BeerPlusPlus;
use Mojo::Base 'Mojolicious';

use BeerPlusPlus::User;

use Data::Printer;
use feature "say";

my $DATADIR = 'users';

# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	# $self->plugin('PODRenderer');

	# create user object
	$self->helper(user => sub { state $user = BeerPlusPlus::User->new($DATADIR) });

	$self->helper(footer => \&footer);

	# Router
	my $r = $self->routes;

	$r->get( '/register' => sub {
		my $self = shift;
		$self->render('register');
	});

	$r->any('/')->to('login#login');

    $r->get('/index')->to('login#login');

	$r->post('/login')->to('login#index');

	$r->get('/logout')->to('login#logout');

	$r = $r->under->to('login#is_auth');

	$r->get('/welcome' => sub { shift->render(template => 'welcome', format => 'html'); });

	$r->get('/statistics')->to('statistics#statistics');

    $r->post('/increment')->to('login#plusplus');

	$r->get('/denied' => sub {
		my $self = shift;
		$self->render(controller => 'denied', subtitle => "rin'tel'noc");
	});

	$r->get('/chpw' => sub { shift->render('register'); });
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
		'/welcome' => 'home',
		'/statistics' => 'statistics',
#		'/chpw' => 'change password',
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
