package BeerPlusPlus;
use strict;
use warnings;
use feature "say";

use Digest::SHA1 qw(sha1_base64);
use Mojolicious::Lite;

no if $] >= 5.018, warnings => "experimental::smartmatch";

# ABSTRACT: first steps to an application which manage the beer storage

post '/login' => sub {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = sha1_base64($self->param('pass'));
    $self->session(user => $user);
    $self->session(pass => $pass);
    # FIXME
    # $hash can be undef
    my $hash = $self->init;
    $self->session(counter => $hash->{counter});
    $self->session(expected_pass => $hash->{pass});
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
        return $hash;
    }
    return undef;
};

helper json2hash => sub {
    my $self = shift;
    my $filename = shift;
    # put more error handling instead of just dying
    open my $fh, '<', 'foo/'.$filename.'.json' or die qq/cannot open $!/;
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
    my @userlist = <../lib/foo/*.json>;
    @userlist = grep { s/.*(?<=\/)(\w+)\.json/$1/ } @userlist;
    return  wantarray ? @userlist : \@userlist;
};

helper user_exists => sub {
    my ($self, $username) = @_;
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
    delete $self->session->{expected_pass};
    my $data = $json->encode($self->session);
    open my $fh, '>', "foo/".$user.".json" || die qq/cannot open $!/;
    print {$fh} $data;
    close $fh;
    return 0;
};

get '/' => 'index';

under sub {
    my $self = shift;
    return 1 if $self->auth;
    $self->render(text => "denied<br/>Rin\'tel\'noc!");
    return 0;
};

get '/statistics' => sub {
    my $self = shift;
    $self->render(controller => 'statistics');
};

get '/logout' => sub {
    my $self = shift;
    delete $self->session->{expected_pass};
    $self->persist;
    %{ $self->session } = ();
    $self->session(expires => 1);
    $self->render(text => 'kree sha!<br/>logging out ...');
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
    my $hash = $self->init;
    $self->session->{expected_pass} = $hash->{pass};
    $self->redirect_to('/welcome');
};

post '/increment' => sub {
    my $self = shift;
    $self->session->{counter}++;
    my $tmp = $self->session->{expected_pass};
    $self->persist;
    $self->session(expected_pass => $tmp);
    $self->redirect_to('/welcome');
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
<title>BeerPlusPlus</title>
</head>
<body>
<div id=1>
%=form_for '/login' => (method => 'POST') => begin
%=text_field 'user'
%=password_field 'pass'
%=submit_button 'login', id => 'login'
%end
</div>
</body>
</html>

