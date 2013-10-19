package BeerPlusPlus;
use Mojo::Base 'Mojolicious';

use BeerPlusPlus::User;

use Data::Printer;
use feature "say";

# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	# $self->plugin('PODRenderer');

	# create user object
	$self->helper(user => sub { state $user = BeerPlusPlus::User->new });

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

	$r->post('/increment' => sub {
		my $self = shift;
		$self->session->{counter}++;
        my $counter = $self->session->{counter};
		$self->user->persist($counter);
		$self->redirect_to('/welcome');
	});

	$r = $r->under(sub {
			my $self = shift;
			$self->render(controller => 'denied', subtitle => "rin'tel'noc");
			return 0;
	});

	$r->get('/denied' => sub {
		my $self = shift;
		$self->render(controller => 'denied', subtitle => "rin'tel'noc");
	});

	$r->get('/chpw' => sub { shift->render('register'); });
}

1;
