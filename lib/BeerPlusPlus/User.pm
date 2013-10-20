package BeerPlusPlus::User;
# use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Data::Printer;
use feature "say";

#FIXME path should be absolute and in config
my $DATADIR = 'users';

#TODO: if tests run the relative path to user dir does not match need to replace
# with a much smarter solution ... now!

sub new { bless {}, shift }

sub init
{
	my ($self, $user)  = @_;
	if ( $self->user_exists($user) ) {
		my $hash = $self->json2hash($user);
        p $hash;
		while (my ($k, $v) = each %{$hash} ) {
			$self->{$k} = $v;
		}
		return $hash;
	}
	return undef;
}

sub user_exists
{
	my ($self, $username) = @_;
	return 0 unless $username;
	my %users = map { $_ => 1 } ( $self->get_users );
	return 1 if (exists $users{$username});
	return 0;
}

sub json2hash
{
	my $self = shift;
	my $filename = shift;
	my $path = "$DATADIR/$filename.json";
	# TODO put more error handling instead of just dying
	open my $fh, '<', $path or die qq/cannot open $path: $!/;
	local $/ = undef;
	my $data = <$fh>;
	close $fh;
	my $json = Mojo::JSON->new;
	my $hashref = $json->decode($data);
	return $hashref;
}

sub get_users
{
	my $self = shift;
	#TODO path to user files should be read from config
	my @userlist = grep { s/(.*\/|\.json$)//g } glob "$DATADIR/*.json";
	return wantarray ? @userlist : \@userlist;
}

sub get_other_usernames
{
    my $self = shift;
    my @otherusers = grep {  !/$self->{user}/ } $self->get_users;
    return wantarray ? @otherusers : \@otherusers;
}

sub get_times_from_user
{
    my ($self, $username) = @_;
    my @times = ();
    if ($username) {
        # get time from specific user
    }
    else {
        @times = @{$self->{times}};
    }
    return wantarray ? @times : \@times;
}

sub get_counter_from_user
{
    my ($self, $username) = @_;
    my $counter = 0;
    if ($username) {
        # get specific user data
    }
    else {
        $counter = $#{$self->{times}};
    }
    return $counter;
}

sub increment
{
    my $self = shift;
    my $timestamp = time;
    push @{$self->{times}}, $timestamp;
    $self->persist();
    return @{$self->{times}};
}

sub persist
{
	my $self = shift;
	my $user = $self->{user};
	my $pass = $self->{pass};
    my @times = @{$self->{times}};
	my $json = Mojo::JSON->new;
	my $data = $json->encode({
							user	=> $user,
							pass	=> $pass,
							times   => \@times,
                        });
    p $data;
	open my $fh, '>', "$DATADIR/$user.json" || die "cannot open $!";
	print {$fh} $data;
	close $fh;
	return 0;
}

sub register
{
	my $self = shift;
	return 0 if $self->param('passwd') ne $self->param('passwd2');
	$self->check($self->param('passwd'), $self->param('passwd2'));
	my $newph = sha1_base64($self->param('passwd'));
	$self->session->{pass} = $newph;
	$self->persist;
	$self->init;
	$self->redirect_to('/welcome');
}

sub check
{
	my $self = shift;
	my $newpw = shift;
	$self->render(text => qq/come on .../) if (length($newpw) < 8);
	return 0;
}

1;
