package Mojar::Message::BulkSms;
use Mojo::Base -base;

our $VERSION = 0.121;

use Mojo::Parameters;
use Mojo::UserAgent;
use Mojo::Util qw(encode url_escape);

# Attributes

has protocol => 'http';
has address => 'www.bulksms.co.uk';
has port => '5567';
has path => 'eapi/submission/send_sms/2/2.0';
has gateway => sub {
  my $self = $_[0];
  $self->path;
  $self->{path} =~ s|^/||;
  sprintf '%s://%s:%s/%s',
      $self->protocol, $self->address, $self->port, $self->path
};

has 'username';
has 'password';
has 'recipient';
has 'sender';
has msisdn => sub { $_[0]->{recipient} };  # read-only alias
has international_prefix => '44';

has 'message';
has 'cb';
has ua => sub { Mojo::UserAgent->new(request_timeout => 15) };
#TODO: replace this with a method that always updates MUD
has debug => sub {
  my $debug = !! $ENV{MOJAR_SMS_DEBUG};
  $ENV{MOJO_USERAGENT_DEBUG} = 1 if $debug;
  $debug
};

# Private function

sub croak { require Carp; goto &Carp::croak; }

# Public methods

sub send {
  my $self = shift;
  $self->cb(pop) if $_[-1] and ref $_[-1] eq 'CODE';
  $self->handle_error(sprintf 'Unhandled args (%s)', join ',', @_)
      unless @_ % 2 == 0;
  %$self = (%$self, @_) if @_;

  my @missing = grep +(not exists $self->{$_}),
      qw(username password recipient message);
  $self->handle_error(sprintf 'Missing parameters (%s)', join ',', @missing)
      if @missing;

  # Clean up recipient
  my $original_recipient = $self->{recipient};
  my $prefix = $self->international_prefix;
  $self->{recipient} =~ s/\D//g;  # collapse non-digits
  $self->{recipient} =~ s/^00//;  # international
  $self->{recipient} =~ s/^0/$prefix/;  # national
  $self->log(sprintf 'Preparing to send SMS to %s (%s)',
      $original_recipient, $self->{recipient}) if $self->debug;
  # Clean up message
  $self->trim_message;

  my $p = Mojo::Parameters->new;
  $p->append($_ => $self->$_) for qw(username password msisdn sender message);

  my ($code, $error) =
      $self->submit(sprintf '%s?%s', $self->gateway, $p->to_string);
  $self->handle_error(sprintf 'Failed (%s) %s', $code, $error) if $code;

#  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  $self->log('Sent to '. $self->recipient) if $self->debug;
  return $self->cb ? $self->cb->($self) : $self;
}

sub submit {
  my ($self, $location) = @_;
  # Call the gateway
  my $tx = $self->ua->get($location);
  # Check http errors
  my ($error, $code) = $tx->error;
  $error //= ''; $code //= 418;
  # Check service errors
  my $msg;
  eval {
    ($code, $msg) = split /\|/, $tx->res->body;
  };
  return !! 0 if length($code // '') == 1 and 0+ $code == 0;
  return wantarray ? ($code, sprintf "%s\n%s", $error, $msg) : $error;
}

sub handle_error {
  my ($self, $error) = @_;
  $error //= '[unknown problem]';
  $self->log($error) if $self->debug;
  return $self->cb->($self, $error) if $self->cb;
  croak $error;
}

sub trim_message {
  my $self = $_[0];
  $self->{message} =~ s/^\s+//;
  $self->{message} =~ s/\s+$//;
  $self->{message} =~ s/\s\s+/ /g;
  return $self;
}

sub log {
  my $self = shift;
  syswrite STDERR, encode 'UTF-8', join "\n", @_, '';
}

1;
__END__

=pod

=head1 NAME

Mojar::Message::BulkSms - Send SMS via BulkSMS service.

=head1 SYNOPSIS

  use Mojar::Message::BulkSms;
  my $sms = Mojar::Message::BulkSms->new(username => ..., password => ...);
  $sms->send(message => q{Guys, have we used up all our credits yet?},
      ->send(recipient => '0776 432 111')
      ->send(recipient => '0778 888 123');

=head1 DESCRIPTION


=head1 ATTRIBUTES

=over 4

=item * protocol

=item * address

=item * port

=item * path

=item * gateway

=item * username

=item * password

=item * recipient

=item * sender

=item * msisdn

=item * international_prefix

=item * message

=item * cb

=item * ua

=item * debug

=back

=head1 METHODS

=over 4

=item new

=item send

=item submit

=item trim_message

=item handle_error

=item log

=back

=head1 REFERENCE

L<http://www.bulksms.co.uk/docs/eapi/> shows the service API.

=head1 CONFIGURATION AND ENVIRONMENT

You need to create an account at L<www.bulksms.co.uk>.

=head1 SUPPORT

See L<Mojar>.

=head1 DIAGNOSTICS

You can get behind-the-scenes debugging info by setting

  MOJAR_SMS_DEBUG=1

in your script's environment.  You should then see all the messages to and from
bulksms.co.uk as well as some progress notes.

=head1 SEE ALSO

L<Net::SMS::BulkSMS> is similar but blocking.
