package BeerPlusPlus;
use strict;
use warnings;

use feature "say";

use Digest::SHA1 qw(sha1_base64);
use Mojolicious::Lite;

no if $] >= 5.018, warnings => "experimental::smartmatch";

# ABSTRACT: first steps to an application which manage the beer storage

my $DATADIR = 'foo';

post '/login' => sub {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = sha1_base64($self->param('pass'));
    $self->session(user => $user);
    $self->session(pass => $pass);
    # FIXME
    # $hash can be undef
    my $hash = $self->init;
    $self->redirect_to('/welcome');
};

get '/register' => sub {
    my $self = shift;
    $self->render(controller => 'register');
};

# init registered user data
helper init => sub {
    my $self = shift;
    $self->res->headers->cache_control('max-age=1, no_cache');
    my $user = $self->session->{user};
    if ( $self->user_exists($user) ) {
        my $hash = $self->json2hash($user);
        $self->session(counter => $hash->{counter});
        $self->session(expected_pass => $hash->{pass});
        return $hash;
    }
    return undef;
};

helper json2hash => sub {
    my $self = shift;
    my $filename = shift;
	my $path = "$DATADIR/$filename.json";
    # TODO put more error handling instead of just dying
    open my $fh, '<', $path or die qq/cannot open $path: $!/;
    $/ = undef;
    my $data = <$fh>;
    close $fh;
    my $json = Mojo::JSON->new;
    my $hashref = $json->decode($data);
    return $hashref;
};

helper get_users => sub {
	my $self = shift;
	# path to user files should be read from config
#	my @userlist = <../lib/foo/*.json>;
#	@userlist = grep { s/.*(?<=\/)(\w+)\.json/$1/ } @userlist;
	my @userlist = map {
		s/^$DATADIR\///; s/\.json$//; $_;
	} glob "$DATADIR/*.json" or warn;
	return wantarray ? @userlist : \@userlist;
};

helper user_exists => sub {
    my ($self, $username) = @_;
	return 0 unless $username;
    my %users = map { $_ => 1 } ( $self->get_users );
    return 1 if (exists $users{$username});
    return 0;
};


helper auth => sub {
    my $self = shift;
    my $user = $self->session->{user};
    return 1 if $self->user_exists($user) &&
    $self->session->{pass} eq $self->session->{expected_pass};
};


helper check => sub {
    my $self = shift;
    my $newpw = shift;
    $self->render(text => qq/come on .../) if (length($newpw) < 8);
    return 0;
};

helper persist => sub {
    my $self = shift;
    my $user = $self->session->{user};
    my $json = Mojo::JSON->new;
    my $tmp = $self->session->{expected_pass};
    delete $self->session->{expected_pass};
    my $data = $json->encode($self->session);
    open my $fh, '>', "$DATADIR/$user.json" || die qq/cannot open $!/;
    print {$fh} $data;
    close $fh;
    $self->session->{expected_pass} = $tmp;
    return 0;
};

get '/' => 'index';

under sub {
    my $self = shift;
    return 1 if $self->auth;
	$self->render('denied', subtitle => "rin'tel'noc");
	return 0;
};

get '/denied' => sub {
	my $self = shift;
	$self->render(controller => 'denied', subtitle => "rin'tel'noc");
};

get '/statistics' => sub {
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
    $self->render(controller => 'statistics', stats => \%statistics);
};

get '/logout' => sub {
    my $self = shift;
    $self->persist;
    delete $self->session->{expected_pass};
    %{ $self->session } = ();
    $self->session(expires => 1);
	my @byebyes = ('kree sha', 'lek tol');
	my $byebye = $byebyes[rand @byebyes];
#	$self->render(text => "$byebye!<br/>logging out ...");
	$self->render(controller => 'logout', byebye => $byebye, subtitle => $byebye);
};

get '/chpw' => sub { shift->render('register'); };

get '/welcome' => sub { shift->render(controller => 'welcome'); };

post '/register' => sub {
    my $self = shift;
    return 0 if $self->param('passwd') ne $self->param('passwd2');
    $self->check($self->param('passwd'), $self->param('passwd2'));
    my $newph = sha1_base64($self->param('passwd'));
    $self->session->{pass} = $newph;
    $self->persist;
    $self->init;
    $self->redirect_to('/welcome');
};

post '/increment' => sub {
    my $self = shift;
    $self->session->{counter}++;
    $self->persist;
    $self->redirect_to('/welcome');
};

app->start;

__DATA__

@@ index.html.ep
% layout 'basic', subtitle => 'increment your blood alcohol level';
%=form_for '/login' => (method => 'POST') => begin
	<table>
		<tr>
			<td class="banner">beer</td>
		</tr>
		<tr>
			<td><%=text_field 'user', id => 'user' %></td>
			<td><%=password_field 'pass', id => 'pass' %></td>
		</tr>
		<tr>
			<td/>
			<td><%=submit_button '++', id => 'login', class => 'banner', title => 'login' %></td>
		</tr>
	</table>
%=end

@@ logout.html.ep
% layout 'basic';
<p class="banner center"><%= $byebye %>!</p>
<div id="footer">
	<span style="float: right"><%=link_to 'login' => '/' %> |</span>
</div>

@@ denied.html.ep
% layout 'basic';
<span class="banner center" style="font-size: 3.7em">Rin'tel'noc!</span>
<br/>
Permission denied!
<div id="footer">
	<span style="float: right"><%=link_to 'login' => '/' %> |</span>
</div>

