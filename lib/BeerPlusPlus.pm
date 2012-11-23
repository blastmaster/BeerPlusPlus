use strict;
use warnings;
use feature "say";
package BeerPlusPlus;

use Mojolicious::Lite;

# ABSTRACT: first steps to an application which manage the beer storage

get '/' => 'index';

get '/statistics' => sub {
    my $self = shift;
    $self->render(controller => 'statistics');
};

post '/welcome' => sub {
    my $self = shift;
    my $user = $self->param('user');
    $self->session->{user} = $user;
    my $pass = $self->param('pass');
    $self->render(controller => 'welcome');
};

post '/increment' => sub {
    my $self = shift;
    $self->session->{counter}++;
    $self->render('welcome');
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
Hello, World!
%=form_for '/welcome' => (method => 'POST') => begin
%=text_field 'user' 
%=password_field 'pass'
%=submit_button 'login', id => 'login'
%end
</body>
</html>

