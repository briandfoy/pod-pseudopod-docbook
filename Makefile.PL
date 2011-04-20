use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Pod::PseudoPod::DocBook',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/Pod/PseudoPod/DocBook.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Pod::PseudoPod'   => '0',
		'Test::LongString' => '0',
		'Test::More'       => '0',
		},

	clean  => { FILES    => q|Pod-DocBook-*| },
	);
