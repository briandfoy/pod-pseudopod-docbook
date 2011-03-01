use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'Pod::PseudoPod::DocBook',
	'ABSTRACT'     => 'This is what the module does',
	'VERSION_FROM' => 'lib/DocBook.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0',
		},

	'PM'           => {
		'lib/DocBook.pm'         => '$(INST_LIBDIR)/DocBook.pm',
		},

	'MAN3PODS'     => {
		'lib/DocBook.pm' => '$(INST_MAN3DIR)/Pod::PseudoPod::DocBook.3',
		},

	clean  => { FILES    => q|Pod-DocBook-*| },

	);
