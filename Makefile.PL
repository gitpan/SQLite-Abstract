use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'SQLite::Abstract',
    'VERSION_FROM'	=> 'Abstract.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM 	=> 'Abstract.pm', # retrieve abstract from module
       AUTHOR     	=> 'Vidul N. Petrov <vidul@cpan.org>') : ( )),
);
