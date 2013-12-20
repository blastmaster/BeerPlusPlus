package BeerPlusPlus::Test::Database;

use strict;
use warnings;

use feature 'say';


=head1 NAME

BeerPlusPlus::Test::Database - module for testing modules which use the
database module internally

=head1 SYNOPSIS

  # initialize an empty test database
  use BeerPlusPlus::Test::Database;

  # load the module to test which uses the database module
  Test::More;
  BEGIN { use_ok('BeerPlusPlus::Module') }

  # work with the module as usual...

=head1 DESCRIPTION

This module is intended for test purposes only since the data get lost
after the application terminated.

=cut


use BeerPlusPlus::Database;
use File::Basename;
use File::Temp 'tempdir';


$BeerPlusPlus::Database::DATADIR
		= tempdir(dirname($0) . '/db.XXXXXXX', CLEANUP => 1);

