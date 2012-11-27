package BeerPlusPlus;
use strict;
use warnings;
use feature "say";

use Digest::SHA1 qw(sha1_base64);
use Mojolicious::Lite;

use Data::Dumper;

# ABSTRACT: first steps to an application which manage the beer storage

post '/login' => sub {
    my $self = shift;
    my $user = $self->param('user');
    my $session = Mojolicious::Sessions->new;
    $session->cookie_name('just_drinking');
    $session->default_expiration(120);
    $session->cookie_path('/foo');
    $session = $session->secure(1);
    my $pass = sha1_base64($self->param('pass'));
    $self->session(user => $user);
    $self->session(pass => $pass);
    my $hash = $self->init;
    $self->session(counter => $hash->{counter});
    $self->session(expected_pass => $hash->{pass});
    $self->redirect_to('/welcome');
};

get '/register' => sub {
    my $self = shift;
    $self->render(controller => 'register');
};

post '/register' => sub {
    my $self = shift;
    say qq/[debug] in post register/;
    say Dumper($self->param);
    say $self->param('name');
    return 0;
};

helper auth => sub {
    my $self = shift;
    return 1 if $self->session->{user} ~~ [qw(blastmaster foo bar)] &&
    $self->session->{pass} eq  $self->session->{expected_pass};
};

# init registered user data
helper init => sub {
    my $self = shift;
    my $user = $self->session->{user};
    return 0 unless -f "foo/".$user.".json";
    my $json = Mojo::JSON->new;
    open my $fh, '<', "foo/".$user.".json" || die qq/cannot open $!/;
    $/ = undef;
    my $data = <$fh>;
    close $fh;
    my $hash = $json->decode($data);
    say qq/[debug] in init/;
    say Dumper($hash);
    return $hash;
};

helper persist => sub {
    my $self = shift;
    my $user = $self->session->{user};
    my $json = Mojo::JSON->new;
    my $data = $json->encode($self->session);
    say qq/[debug] in persist/;
    say Dumper($data);
    open my $fh, '>', "foo/".$user.".json" || die qq/cannot open $!/;
    print {$fh} $data;
    close $fh;
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
    say qq/[debug] in logout/;
    say Dumper($self->session);
    delete $self->session->{expected_pass};
    $self->persist;
    delete $self->session->{user};
    delete $self->session->{pass};
    delete $self->session->{counter};
    $self->render(text => 'kree sha!<br/>logging out ...');
};

get '/welcome' => sub { shift->render(controller => 'welcome'); };

post '/increment' => sub {
    my $self = shift;
    $self->session->{counter}++;
    $self->redirect_to('welcome');
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
<div>
%=form_for '/login' => (method => 'POST') => begin
%=text_field 'user'
%=password_field 'pass'
%=submit_button 'login', id => 'login'
%end
</div>
<div>
%= link_to Register => '/register'
</div>
</body>
</html>

