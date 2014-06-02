# ============
# bulksms.t
# ============
package _Mock::Message;
use Mojo::Base -base;
has 'body';

package main;
use Mojo::Base -strict;
use Mojar::Message::BulkSms;

package Mojar::Message::BulkSms;
no warnings 'redefine';
$Mojar::Message::BulkSms::response = [0, 'IN_PROGRESS'];

sub submit {
  wantarray ? @$Mojar::Message::BulkSms::response : $Mojar::Message::BulkSms::response->[0];
}

package main;
use Test::More;

# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

my $sms;

subtest q{Basic} => sub {
  ok $sms = Mojar::Message::BulkSms->new(
    username => 'some_user',
    password => 'some_pissword'
  );
};

subtest q{Env} => sub {
  $ENV{MOJAR_SMS_DEBUG} = 1;
  ok $sms->debug, 'debug on';
  delete $sms->{debug} and $ENV{MOJAR_SMS_DEBUG} = 0;
  ok ! $sms->debug, 'debug off';
};

subtest q{Parameters} => sub {
  eval {
    $sms->send;
  };
  ok $@, 'threw exception';
  ok $@ =~ /Missing parameters/, 'identified problem';
  ok $@ =~ /recipient/, 'highlighted recipient';
  ok $@ =~ /message/, 'highlighted message';

  $sms->recipient('0044 78-23 12 99');
  eval {
    $sms->send;
  };
  ok $@ =~ /Missing parameters/, 'identified problem again';
  ok $@ !~ /recipient/, 'has recipient';

  eval {
    $sms->send(message => q{ Some text });
  };
  ok ! $@, 'no exception' or diag $@;
  is $sms->recipient, '4478231299', 'recipient cleansed';
  is $sms->message, 'Some text', 'message trimmed';

  ok $sms->send(message => q{Other text }), 'send ok';
  is $sms->recipient, '4478231299', 'recipient intact';
  is $sms->message, 'Other text', 'message changed';

  ok $sms->send(recipient => q{+44 781 2676 398}), 'send ok';
  is $sms->recipient, '447812676398', 'recipient cleansed';
  is $sms->message, 'Other text', 'message intact';

  $sms->international_prefix('33');
  ok $sms->send(recipient => q{0781 2676 398}), 'send ok';
  is $sms->recipient, '337812676398', 'recipient cleansed';

  ok $sms->send, 'repeat sending with cached details';
};

subtest q{Chaining} => sub {
  ok $sms->send(message => q{We're back on the chain gang!})
      ->send(recipient => '07768 321 123')
      ->send(recipient => '07768 123 321');
};

subtest q{Response} => sub {
  $Mojar::Message::BulkSms::response =
      [23, 'invalid credentials (username was: mud)'];
  eval {
    $sms->send;
  };
  ok $@, 'threw exception';
  ok $@ =~ /Failed \(23\)/, 'identified code';
  ok $@ =~ /invalid credentials/, 'identified problem';

  $Mojar::Message::BulkSms::response =
      [24, 'invalid msisdn: 44'];
  eval {
    $sms->send;
  };
  ok $@, 'threw exception';
  ok $@ =~ /Failed \(24\)/, 'identified code';
  ok $@ =~ /invalid msisdn/, 'identified problem';
};

done_testing();
