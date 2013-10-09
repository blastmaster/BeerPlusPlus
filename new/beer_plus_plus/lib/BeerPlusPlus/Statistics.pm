package BeerPlusPlus::Statistics;
use Mojo::Base 'Mojolicious::Controller';

#FIXME second time same variable, get rid of this and use config
my $DATADIR = '../../users';

sub statistics
{
	my $self = shift;
	my $user = $self->session->{user};
	my %statistics;
	for my $userfile (glob "$DATADIR/*.json") {
		my ($name) = $userfile =~ /$DATADIR\/(.+)\.json$/;
		next if $name eq $user;

		open FILE, '<', $userfile or die $!;
		my $hash = $self->json2hash($name);
		close FILE or warn $!;
		$statistics{$name} = $hash->{counter};
	}
	$self->render('statistics', stats => \%statistics);
}

1;
