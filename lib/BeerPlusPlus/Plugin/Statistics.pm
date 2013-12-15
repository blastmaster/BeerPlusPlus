package BeerPlusPlus::Plugin::Statistics;

use strict;
use warnings;

use feature 'say';


sub initialize($) {
	my $self = shift;

	$self->routes->get('/statistics' => \&statistics);

	return '/statistics' => 'statistics';
}

sub statistics($) {
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

