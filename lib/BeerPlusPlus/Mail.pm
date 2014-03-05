package BeerPlusPlus::Mail;

use strict;
use warnings;

use feature "say";

=head1 NAME

BeerPlusPlus::Mail - module to provide mail support

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use BeerPlusPlus::Mail;

    # set include path for template files
    $BeerPlusPlus::Mail::TEMPLATE_DIR = 'BeerPlusPlus/templates/';

    # create new mail with destination address and subject
    my $mail = BeerPlusPlus::Mail->new(
                                        To => you@youhost.com,
                                        Subject => "Hello Beer");
    # setting a template file
    $mail->set_template('path/to/my/template.tt');

    # setting parameters in template file
    $mail->set_template_params(%params);

    # adding a pdf attachment
    $mail->attach(Type => 'application/pdf',
                  Path => '/path/to/my.pdf',
                  Filename => 'Beeroffer.pdf');

    # finish with sending the mail
    $mail->send('mail.youhost.com');


=head1 DESCRIPTION

The mail module is intended to provide the ability writing mails to users of the
BeerPlusPlus system. It uses MIME::Lite::TT under the hood and is just a
container for template and attachment data. It does no input validation.

=cut

use Carp;

# FIXME:
# setting template dir to something useful by default !!!
our $TEMPLATE_DIR = "";

=head2 OBJECT METHODS

=over 11

=item BeerPlusPlus::Mail->new(%params)

Creates a new mail object with the given parameters for the mail.
If there is no template options for MIME::Lite::TT given, it sets the
INCLUDE_PATH option to the global C<$TEMPLATE_DIR> variable.

=cut

sub new
{
    my $class = shift;
    my %params = @_;

    $params{TmplOptions} = { INCLUDE_PATH => $TEMPLATE_DIR, } unless defined $params{TmplOptions};
    my $self = { params => \%params,
                 attached => undef,
               };

    return bless $self, $class;
}

=item $mail->get_subject()

Returns the subject of that mail.

=cut

sub get_subject
{
    my $self = shift;

    return $self->{params}->{Subject};
}

=item $mail->get_template()

Returns the template of the mail.

=cut

sub get_template
{
    my $self = shift;

    return $self->{params}->{Template};
}

=item $mail->get_template_options()

Returns the template options hash.

=cut

sub get_template_options
{
    my $self = shift;

    return $self->{params}->{TmplOptions};
}

=item $mail->get_template_params()

Returns the template parameter hash.

=cut

sub get_template_params
{
    my $self = shift;

    return $self->{params}->{TmplParams};
}

=item $mail->set_subject($subject)

Sets the given subject to the subject of the mail.

=cut

sub set_subject
{
    my $self = shift;
    my $subject = shift;

    $self->{params}->{Subject} = $subject;
}

=item $mail->set_template($template_file)

Sets the given template file as template for the mail.

=cut

sub set_template
{
    my $self = shift;
    my $template = shift;

    $self->{params}->{Template} = $template;
}

=item $mail->set_template_options(%options)

Sets the given template options these are the template options for
MIME::Lite::TT.

=cut

sub set_template_options
{
    my $self = shift;
    my %options = @_ or carp "no options to set";

    $self->{params}->{TmplOptions} = \%options;
}

=item $mail->set_template_params(%params)

Sets the given template parameter these are the template parameters for
MIME::Lite::TT.

=cut

sub set_template_params
{
    my $self = shift;
    my %params = @_ or carp "no params to set";

    $self->{params}->{TmplParams} = \%params;
}

=item $mail->attach(%params)

Saves the parameters for attachements if the C<send> method is called these
parameters will passed through the MIME::Lite::attach method.

Possible Parameters are Type, Path and Filename.

=cut

sub attach
{
    my $self = shift;
    my %attach_info = @_;

    $self->{attached} = \%attach_info;
}

=item $mail->send($mail_host)

This method gets the mail host which is the smtp host of the reciever.
Creates a new BeerPlusPlus::Mail::Mailer Object and pass the stored parameters
to it. It also add attachements if defined before.

=cut

sub send
{
    my $self = shift;
    my $mail_host = shift;
    my $mailer = BeerPlusPlus::Mail::Mailer->new(%{$self->{params}});
    $mailer->{msg}->attach(%{$self->{attached}}) if $self->{attached};
    $mailer->send_mail($mail_host);
}


=back

=cut

package BeerPlusPlus::Mail::Mailer;

use MIME::Lite::TT;
use Carp;

our $FROM_ADDR = 'BeerPlusPlus@beer.de';

=over 3

=item BeerPlusPlus::Mail->new(%params)

Create Mailer Object, with params gathered form BeerPlusPlus::Mail class.
If the from address field is not set in the parameters passed to the method it
is set to C<$FROM_ADDR>.

=cut

sub new
{
    my $class = shift;
    my %params = @_;

    $params{From} = $FROM_ADDR unless defined $params{From};

    my $self = {
            msg => MIME::Lite::TT->new( %params ),
    };

    return bless $self, $class;
}

=item $mailer->set_data($data)

DEPRECATED
This method sets given data in data field of the mail.

=cut

sub set_data
{
    my $self = shift;
    my $data = shift or croak "no data given";

    $self->msg->add(Data => $data);
}

=item $mailer->send_mail('mail.youhost.com')

Sending message to the given mailost using smtp.
Timeout is set to 60 seconds.

=cut

sub send_mail
{
    my $self = shift;
    my $mail_host = shift;

    $self->{msg}->send('smtp', $mail_host, Timeout => 60);
}

=back

=cut

1;

=head1 AUTHOR

blastmaster, E<lt>blastmaster@tuxcode.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Innercircle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
