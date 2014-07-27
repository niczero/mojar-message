package Mojar::Message::Smtp;
use Mojo::Base -base;

our $VERSION = 0.001;

use Mojar::Cron::Util 'tz_offset';
use Mojo::Log;
use POSIX 'strftime';

# Attributes

# Protocol
has ssl => 0;
has host => '127.0.0.1';
has port => sub { shift->ssl ? 465 : 25 };
has [qw(user secret)];  # SASL username, password
has domain => 'localhost.localdomain';  # for helo handshake
has timeout => 120;
has debug => 1;
has date_pattern => '%a, %d %b %Y %H:%M:%S';

# Message
has From => sub { ($ENV{USER} // $ENV{USERNAME} // '_').'@'. shift->domain };
has [qw(To Cc Bcc)];
has [qw(Subject body)] => '';

# Agent
has agent => sub {
  my $self = shift;
  my %param = (
    Host => $self->host,
    Port => $self->port,
    Hello => $self->domain,
    Timeout => $self->timeout,
    Debug => $self->debug
  );
  my $fail = sub { $self->fail(@_) };

  my $class = $self->ssl ? 'Net::SMTP::SSL' : 'Net::SMTP';
  (my $file = $class) =~ s{::}{/}g;
  require "${file}.pm" or $self->fail("Failed to load $class\n$!");
  my $agent = $class->new(%param)
    or $self->fail("Failed to connect to server\n$!");

  if ($self->user) {
    $fail->('Missing required auth secret') unless defined $self->secret;
    unless ($agent->auth($self->user, $self->secret)) {
      my $msg = $agent->message // '';
      $fail->('Missing MIME::Base64 (AUTH)') if $msg =~ /MIME::Base64/;
      $fail->('Missing Authen::SASL (AUTH)') if $msg =~ /Authen::SASL/;
      $fail->("Failed authentication\n$!\n$msg");
    }
  }
  return $agent;
};
has log => sub { Mojo::Log->new };

# Public methods

sub send {
  my $self = shift;
  my $agent = $self->agent;
  my $fail = sub { $self->fail(@_) };
  my @to = ref $self->To ? @{$self->To} : $self->To;
  $self->{Date} = $self->date;
  $self->{'User-Agent'} = sprintf '%s/%.3f', __PACKAGE__, $VERSION;
  my $content = $self->content;

  $agent->mail($self->From) or $fail->("Failed communicating (FROM)\n$!");

  my @rcpts = map { [ $agent->to($_), $_ ] } @to;
  my @bad = map +($_->[1]), grep +(not $_->[0]), @rcpts;  # Bad recipients
  if (my $fails = scalar @bad) {
    $fail->(sprintf "%s addresses rejected (RCPT):\n%s",
        ($fails == @rcpts ? 'all '. $fails : $fails), join '|', @bad);
  }

  $agent->data or $fail->("Failed beginning (DATA) $!");
  $agent->datasend($content) or $fail->("Failed communicating (DATA) $!");
  $agent->dataend or $fail->("Failed end (DATA)\n$!\n$(\ $agent->message )");
  $agent->quit;
  return $self;
}

sub content {
  my $self = shift;
  my $header = '';
  $header .= sprintf "%s: %s\n", $_, $self->{$_}
    for grep +($_ =~ /^[A-Z]/), keys %$self;  # Titlecase fields
  return $header ."\n". $self->body ."\n";
}

sub date { strftime($_[0]->date_pattern, localtime) .' '. tz_offset }

sub fail {
  my $self = shift;
  $self->log->error(@_);
  die join("\n", @_) ."\n";
}

1;
__END__

=head1 NAME

Mojar::Message::Smtp - Lightweight email sender.

=head1 SYNOPSIS

  use Mojar::Message::Smtp;
  my $email = Mojar::Message::Smtp->new(
    domain => 'example.com',
    log => $app_log
  );

  $email->To('myteam@example.com')
      ->From('manager@example.com')
      ->Subject(q{Team, is your inbox full?})
      ->body(q{Otherwise, consider this JPG your reward.})
      ->attach({path => '/tmp/random.jpg', filename => undef})
      ->send;
  $email->To('otherteam@example.com')->send;

=head1 DESCRIPTION

Sends a plain text email, possibly with attachments, via an SMTP mailserver.

=head1 ATTRIBUTES

=over 4

=item * log

  $email->log($logger);
  $email->log->debug('Making progress');

A L<Mojo::Log> compatible logger, eg L<Mojar::Log>.

=item * ssl

  $email->ssl(1);
  say $email->ssl ? 'secure' : 'insecure';

=back

=head1 METHODS

=over 4

=item new

  $email = Mojar::Message::Smtp->new(domain => ..., ...);

Constructor for the SMTP sender.

=item send

  $sent = $email->send;

Sends an SMTP message.

=item other methods

See the source code for other methods you can override when subclassing this.

=back

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<MIME::Entity>.
