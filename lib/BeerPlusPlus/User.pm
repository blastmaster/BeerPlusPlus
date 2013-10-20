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
			say "k = $k\tv = $v";
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
	say "exists!!!" if -d $DATADIR;
	say "datadir: $DATADIR";
	my @userlist = grep { s/(.*\/|\.json$)//g } glob "$DATADIR/*.json";
	p @userlist;
	return wantarray ? @userlist : \@userlist;
}

sub persist
{
	my ($self, $counter) = @_;
	p $self;
	my $user = $self->{user};
	say "in persist counter: $counter";
	my $pass = $self->{pass};
	my $json = Mojo::JSON->new;
	my $data = $json->encode({
							user	=> $user,
							counter => $counter,
							pass	=> $pass
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
