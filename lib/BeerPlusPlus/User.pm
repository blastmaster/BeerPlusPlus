package BeerPlusPlus::User;

use Mojo::JSON;
use Digest::SHA qw(sha1_base64);
use Cwd 'abs_path';
use File::Basename;

use Data::Printer;
use feature "say";

# TODO: passing hash to constructor
# datadir => $datadir
# username => $username
sub new
{
    my ($class, $datadir) = @_;
    return bless {datadir => $datadir}, $class;
}

sub init
{
	my ($self, $user)  = @_;
	if ( $self->user_exists($user) ) {
		my $hash = $self->json2hash($user);
		while (my ($k, $v) = each %{$hash} ) {
			$self->{$k} = $v;
		}
		return $hash;
	}
	return undef;
}

sub create_users
{
    my $self = shift;
	my @usernames = @_;
	for my $username (@usernames) {
		my $pass = sha1_base64('lukeichbindeinvater');
		my %new_user = (
			user => $username,
			pass => $pass,
			times => [],
		);

		my $json = Mojo::JSON->new;
		my $data = $json->encode(\%new_user);

		my $userfile = "$self->{datadir}/$username.json";
		unless (-f $userfile) {
			open my $fh, '>', $userfile or die qq/cannot open $userfile: $!/;
			print {$fh} $data;
			close $fh or warn "cannot close $userfile: $!";
		} else {
			say STDERR "warn: user '$username' already exists!";
		}
	}
}

sub user_exists
{
	my ($self, $username) = @_;
	return 0 unless $username;
	my %users = map { $_ => 1 } ( $self->get_usernames );
	return 1 if (exists $users{$username});
	return 0;
}

sub json2hash
{
	my $self = shift;
	my $username = shift;
	my $path = "$self->{datadir}/$username.json";
	# TODO put more error handling instead of just dying
	open my $fh, '<', $path or die qq/cannot open $path: $!/;
	local $/ = undef;
	my $data = <$fh>;
	close $fh;
	my $json = Mojo::JSON->new;
	my $hashref = $json->decode($data);
	return $hashref;
}

# TODO: make password change more safe
sub set_attribute
{
    my $self = shift;
    my %attrs = @_;
    my $changed = 0;
    while (my ($k, $v) = each(%attrs)) {
        $self->{$k} = $v;
        warn "[DEBUG] setting user attribute $k = $v";
        ++$changed;
    }
    return $changed;
}

# WARNING: get_user, get_users and get_others returns unblessed list of hashes
# at the time.

sub get_user
{
    my ($self, $username) = @_;
    my $userhash = $self->init($username);
    return $userhash;
}

sub get_users
{
    my $self = shift;
    my @userlist = $self->get_usernames();
    my @user_obj_list = map { $self->init($_) } @userlist;
    return wantarray ? @user_obj_list : \@user_obj_list;
}

sub get_others
{
    my $self = shift;
    my @otherslist = $self->get_other_usernames();
    my @others_obj_list = map { $self->init($_) } @otherslist;
    return wantarray ? @others_obj_list : \@others_obj_list;
}

sub get_usernames
{
	my $self = shift;
	#TODO path to user files should be read from config
	my @userlist = grep { s/(.*\/|\.json$)//g } glob "$self->{datadir}/*.json";
	return wantarray ? @userlist : \@userlist;
}

sub get_other_usernames
{
    my $self = shift;
    my @usernames = $self->get_usernames();
    my @otherusers = grep {  !/$self->{user}/ } @usernames;
    return wantarray ? @otherusers : \@otherusers;
}

sub get_timestamps
{
    my $self = shift;;
    my @times = ();
    @times = @{$self->{times}};
    return wantarray ? @times : \@times;
}

sub get_counter
{
    my $self = shift;
    my $counter = 0;
    $counter = @{$self->{times}};
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
	open my $fh, '>', "$self->{datadir}/$user.json" || die "cannot open $!";
	print {$fh} $data;
	close $fh;
	return 0;
}

1;
