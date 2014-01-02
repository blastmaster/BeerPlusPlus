package BeerPlusPlus::Plugin::Statistics;

use strict;
use warnings;

use feature 'say';


sub initialize($) {
	my $self = shift;

	$self->routes->get('/statistics' => \&statistics);

#	$self->linkman->add('/statistics' => 'statistics');

	return '/statistics' => 'statistics';
}

sub statistics($) {
	my $self = shift;

	my %statistics;
    for my $user ($self->user->get_others()) {
        my $name = $user->get_name();
        my $count = $user->get_count();
        $statistics{$name} = $count if $count;
    }

	my $user = $self->user;
	$self->stash(user => $user->get_name());
	$self->stash(count => $user->get_count());
    $self->render(template => 'statistics', stats => \%statistics);
}


1;

