use strict;
use warnings;
use feature "say";
package BeerPlusPlus;

use Mojolicious::Lite;
plugin "TagHelpers";

# ABSTRACT:

get '/' => 'index';

post '/welcome' => sub {
    my $self = shift;
    my $user = $self->param('user');
    my $pass = $self->param('pass');
    $self->render(text => "$user $pass");
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

