package BeerPlusPlus::Statistics;
use Mojo::Base 'Mojolicious::Controller';

sub statistics
{
	my $self = shift;

	my %statistics;
    my @otherusers = $self->user->get_others();

    for my $userhash (@otherusers) {
        # hash accesses will be replaced by suitable method call's
        my $name = $userhash->{user};
        my $count = @{$userhash->{times}};
        $statistics{$name} = $count if $count;
    }

    $self->render(template => 'statistics', stats => \%statistics);
}

1;
