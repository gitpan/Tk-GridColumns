use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::GridColumns',
    VERSION_FROM      => 'lib/Tk/GridColumns.pm', # finds $VERSION
    PREREQ_PM         => {Tk => 804}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/GridColumns.pm', # retrieve abstract from module
       AUTHOR         => 'Matthias Wienand <matthias.wienand@googlemail.com>') : ()),
);
