# ============
# send.t
# ============
use Mojo::Base -strict;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Mojar::Message::BulkSms;
use Mojar::Config;

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

my $config = Mojar::Config->load('data/credentials.conf');
my $sms;

subtest q{send} => sub {
  ok $sms = Mojar::Message::BulkSms->new(
    username => $config->{username},
    password => $config->{password}
  );
  ok $sms->send(
    recipient => $config->{recipient},
    message => 'Testing $50 or £9 up ~10%!'
  );
};

done_testing();
