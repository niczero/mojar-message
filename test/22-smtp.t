use Mojo::Base -strict;

use Test::More;
use Mojar::Message::Smtp;

my $sender;

subtest q{new} => sub {
  ok $sender = Mojar::Message::Smtp->new(
    From => 'nsandfield@ebuyer.com',
    To => 'nic.sandfield@ebuyer.com',
    domain => 'dev.ebuyer.com'
  ), 'new';
};

subtest q{send} => sub {
  ok $sender->Subject('Test')->body('Testing')->send, 'send';
};

done_testing();
