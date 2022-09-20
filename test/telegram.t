use Mojo::Base -strict;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojar::Config;
use Mojar::Message::Telegram;

plan skip_all => 'set TEST_TELEGRAM to enable this test (developer only!)'
  unless my $filename = $ENV{TEST_TELEGRAM};

die 'Expects a .conf configuration file' unless $filename =~ /\.conf$/;
my $config = Mojar::Config->load($filename);
my $recipient = $config->{telegram}{friends}[0]{id};
my $msg;

subtest q{Synchronous} => sub {
  ok $msg = Mojar::Message::Telegram->new(
    token => $config->{telegram}{token}
  ), 'construct Telegram agent';
  ok $msg->send(
    message   => 'First test message',
    recipient => $recipient,
  ), 'send first message (sync)';
  ok $msg->send(
    message   => "Second message: \N{U+26A0} \N{U+2714} \N{U+2620}",
    recipient => $recipient,
  )->send(
    message   => "Third message: \N{U+1F4A9}",
    recipient => $recipient,
  ), 'send more messages (sync)';
};

#subtest q{Asynchronous} => sub {
#  my @results;
#  my $delay = Mojo::IOLoop->delay;
#  my @end = ($delay->begin, $delay->begin);
#  ok $msg->send(message => 'First asynchronous message' => sub {
#    my ($s, $e) = @_;
#    $results[0]++;
#    $end[0]->();
#  })
#      ->send(message => 'Second asynchronous message' => sub {
#    $results[1]++;
#    $end[1]->();
#  }), 'Sent async';
#  $delay->wait;
#  ok $results[0], 'First callback';
#  ok $results[1], 'Second callback';
#};

done_testing();
