#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Spec::Functions;
require 't/lib/transform_file.pl';

chdir 'test-corpus';
my @files = glob( '*.pod' );
chdir '..';
print STDERR "Found @files\n";

foreach my $file ( @files ) {
	transform_file( $file );
	}
