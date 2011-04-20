use Test::LongString;

my $class = 'Pod::PseudoPod::DocBook';
use_ok( $class );

my $input_dir = 'test-corpus';
ok( -d $input_dir, "Input directory is there" );


sub transform_file
	{
	my( $pod_file ) = shift;
	
	use File::Spec;
	
	my $parser = $class->new();
	isa_ok( $parser, $class );
	
	my $file = File::Spec->catfile( $input_dir, $pod_file );
	
	ok( -e $file, "Input file is there" );
	
	$parser->no_whining( ! ( $ENV{DEBUG} || 0 ) );
	$parser->set_title( 'test-title' );
	$parser->set_chapter( 3 );
	$parser->complain_stderr( 1 );
	$parser->output_string( \my $output );
	$parser->parse_file( $file );
	
	( my $output_reference = $file ) =~ s/.pod$/.xml/;
	
	ok( -e $output_reference, "Output reference file is there" );
	
	my $expected_output = do { local $/; local @ARGV = $output_reference; <> };
	
	is_string( $output, $expected_output, "Regression for $pod_file" );
	
	if( $ENV{DEBUG} )
		{
		open my( $fh ), ">", "$output_reference.debug"
			or die "Could not open debug file: $!\n";
		print $fh "$output\n"
		}
	}
	
1;

