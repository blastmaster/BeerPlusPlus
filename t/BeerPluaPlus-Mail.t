#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use BeerPlusPlus::User;
use Data::Printer;
use POSIX qw(strftime);
use Test::More  'no_plan';

BEGIN { use_ok('BeerPlusPlus::Mail'); }

our $FORMAT = "%d.%m.%Y";

sub get_time_period
{
    # shift if $_[0] eq __PACKAGE__ or ref $_[0] eq  __PACKAGE__;
    return map { strftime($FORMAT, gmtime($_)) } sort @_;
}

my $name = "foo";
my $password = "la;sjdfvnwoie";
my $mail_addr = 'blastmaster@tuxcode.org';
my $subject = 'Testing Test';
my $data = 'check your bloodalcohol befor commit';

# TODO:
# creating test user, delete after the show is gone
BeerPlusPlus::User->create($name, $password);
my $user = BeerPlusPlus::User->new('foo');
ok(defined $user, "user defined");
$user->set_email($mail_addr);
is($user->get_email(), $mail_addr, "mail is set");

# increment count
$user->consume();

# TODO:
# slicing first and last entry, should use payoff instead of zero if it has a useful value
# my ($start_date, $end_date) =  get_time_period(@timestamps[0, $#timestamps]);
my @timestamps = $user->get_timestamps();
my ($start, $end) = get_time_period(@timestamps[0, $#timestamps]);
like($start, qr/^[\d{1,4}\.?]+$/, "got expected string pattern");
like($end, qr/^[\d{1,4}\.?]+$/, "got expected string pattern");

my %params = (
            user_name => "foo",
            amount => 42,
            start_date => $start,
            end_date => $end,
            );

my %options = ( INCLUDE_PATH => "t/templates/" );

# set a default
$BeerPlusPlus::Mail::TEMPLATE_DIR = "templates/";

my $mo = BeerPlusPlus::Mail->new(To => $mail_addr, Subject => $subject);
isa_ok($mo, 'BeerPlusPlus::Mail');
isa_ok(BeerPlusPlus::Mail->new(To => $mail_addr, Subject => $subject), 'BeerPlusPlus::Mail');

is_deeply($mo->get_template_options(),
    { INCLUDE_PATH => $BeerPlusPlus::Mail::TEMPLATE_DIR },
    "right default include path");

ok($mo->get_subject() eq $subject, "getting subject");

my $tt = "billingmail.tt";
$mo->set_template($tt);
my $rt = $mo->get_template();
is($rt, $tt, "template get/set");

$mo->set_template_params(%params);
my $pa = $mo->get_template_params();
is_deeply($pa, \%params, "template params get/set");

$mo->set_template_options(%options);
my $op = $mo->get_template_options();
is_deeply($op, \%options, "template options get/set");

my $mailer = BeerPlusPlus::Mail::Mailer->new(
                            (To => $mail_addr,
                             Subject => $mo->get_subject,
                             Template => $mo->get_template(),
                             TmplOptions => \%options,
                             TmplParams => \%params,)
                        );

isa_ok($mailer, 'BeerPlusPlus::Mail::Mailer', 'create Mailer object');

$mo->attach(Type => 'application/pdf',
            Path => './PGAS.pdf',
            Filename => 'urrghs.pdf',
        );

# $mailer->send_mail('mail.tuxcode.org');
# $mo->send('mail.tuxcode.org');

