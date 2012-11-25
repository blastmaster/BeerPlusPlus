use strict;
use warnings;

use feature "say";

use Mojolicious::Lite;

package BeerPlusPlus;

# ABSTRACT: Webapplication to manage beer storage


get '/' => 'index';

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
%end
</body>
</html>

