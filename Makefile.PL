
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Dancer HTML Form and Grid/Table engine with Input Validation',
  'AUTHOR' => 'Al Newkirk <awncorp@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Dancer-Plugin-DataFu',
  'EXE_FILES' => [
    'scripts/dancer-datafu'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Dancer::Plugin::DataFu',
  'PREREQ_PM' => {
    'Array::Unique' => '0',
    'Dancer' => '0',
    'Data::Dumper::Concise' => '0',
    'File::ShareDir' => '0',
    'Hash::Merge' => '0',
    'Oogly' => '0.31',
    'Template' => '0'
  },
  'VERSION' => '1.103070',
  'test' => {
    'TESTS' => ''
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



