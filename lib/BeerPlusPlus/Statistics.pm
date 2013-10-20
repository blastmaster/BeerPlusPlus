package BeerPlusPlus::Statistics;
use Mojo::Base 'Mojolicious::Controller';

#FIXME second time same variable, get rid of this and use config
my $DATADIR = 'users';

sub statistics
{
	my $self = shift;
	my $user = $self->session->{user};

	my %statistics;
	for my $userfile (glob "$DATADIR/*.json") {
		my ($name) = $userfile =~ /$DATADIR\/(.+)\.json$/;
		next if $name eq $user;

		open FILE, '<', $userfile or die $!;
		my $hash = $self->user->json2hash($name);
		close FILE or warn $!;

		my $count = $hash->{counter};
		$statistics{$name} = $count if $count;
	}
	$self->render(template => 'statistics', stats => \%statistics);
}

1;
