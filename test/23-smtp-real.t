use Mojo::Base -strict;

use Test::More;
use Mojar::Message::Smtp;

use Mojar::Config;

my $config = Mojar::Config->load('data/smtp.conf');
my $email;

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

subtest q{new} => sub {
  ok $email = Mojar::Message::Smtp->new(
    From => $config->{From},
    To => $config->{To},
    domain => $config->{domain}
  ), 'new';
};

subtest q{send} => sub {
  ok $email->Subject('Test')->body('Testing')->send, 'send';
  ok $email->Subject('Test 2')->body("Testing\n2")->send, 'send again';
};

subtest q{attach} => sub {
  ok $email->Subject('test with attachment')->body('Body')->attach(
    Path => '/tmp/x/twinkle_lite_app.conf'
  )->Cc($config->{Cc})->send, 'send attachment';
};

done_testing();
