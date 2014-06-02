use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar::Message',
  VERSION_FROM => 'lib/Mojar/Message.pm',
  ABSTRACT     => 'Send messages',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => 5.010001},
    resources => {
      homepage    => 'http://niczero.github.com/mojar-message',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojar-message',
      bugtracker  => 'http://github.com/niczero/mojar-message/issues'
    },
    no_index => {directory => [qw(data test)]}
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '6.30'},
  PREREQ_PM => {
    Mojolicious => 3.33,
    Mojar => 1
  },
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);
