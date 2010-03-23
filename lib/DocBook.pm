package Pod::DocBook;
use strict;
use base 'Pod::PseudoPod';

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

use Carp;

$VERSION = '0.10';

=head1 NAME

Pod::DocBook - Turn Pod into Microsoft Word's WordML

=head1 SYNOPSIS

	use Pod::DocBook;

=head1 DESCRIPTION

***THIS IS ALPHA SOFTWARE. MAJOR PARTS WILL CHANGE***

I wrote just enough of this module to get my job done, and I skipped every
part of the specification I didn't need while still making it flexible enough
to handle stuff later. 

=head2 The style information

I don't handle all of the complexities of styles, defining styles, and
all that other stuff. There are methods to return style names, and you
can override those in a subclass.

=cut

=over 4

=item document_header

This is the start of the document that defines all of the styles. You'll need
to override this. You can take this directly from 

=cut

sub add_xml_tag
	{
	my( $self, $stuff ) = @_;

	$self->add_to_scratch( $stuff );
	$self->emit;
	}

sub add_data
	{
	my( $self, $stuff ) = @_;

	$self->add_to_scratch( $stuff );
	$self->escape_and_emit;
	}

sub escape_and_emit
	{
	my( $self ) = @_;

	$self->{'scratch'} =~ s/\s+\z//;
	
	$self->{'scratch'} =~ s/&/&amp;/g;
	$self->{'scratch'} =~ s/</&lt;/g;
	$self->{'scratch'} =~ s/>/&gt;/g;

	$self->emit;
	}
	
sub add_to_scratch 
	{
	my( $self, $stuff ) = @_;

	$self->{scratch} .= $stuff;
	}

sub clear_scratch 
	{
	my( $self ) = @_;

	$self->{scratch} = '';
	}

sub set_title   {  $_[0]->{title} = $_[1] }
sub set_chapter {  $_[0]->{chapter} = $_[1] }

sub title      { $_[0]->{title}      }
sub chapter    { $_[0]->{chapter}    }
sub section    { $_[0]->{section}    }
sub subsection { $_[0]->{subsection} }

sub document_header  
	{
	my $string = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE chapter PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN" 
	"http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">
XML

	my $id = join '-', $_[0]->title, $_[0]->chapter;

	$string .= <<"XML";
<chapter id="$id">

XML
	}

=item document_footer

=cut

sub document_footer
	{
	my $string = '';

	foreach my $section (  @{ $_[0]->{in_section} } )
		{
		$string .= "</sect$section>\n";
		}

	$string .= <<'XML';
</chapter>
XML
	}

=back

=head2 The Pod::Simple mechanics

Everything else is the same stuff from C<Pod::Simple>.

=cut

use Data::Dumper;
sub new { my $self = $_[0]->SUPER::new() }

sub emit 
	{
	print {$_[0]->{'output_fh'}} $_[0]->{'scratch'};
	$_[0]->clear_scratch;
	return;
	}

sub get_pad
	{
	# flow elements first
	   if( $_[0]{module_flag}   ) { 'scratch'   }
	elsif( $_[0]{url_flag}      ) { 'url_text'      }
	# then block elements
	# finally the default
	else                          { 'scratch'       }
	}

sub start_Document
	{
	$_[0]->{in_section} = [];
	$_[0]->add_to_scratch( $_[0]->document_header ); 
	$_[0]->emit;
	}

sub end_Document    
	{
	$_[0]->add_to_scratch( $_[0]->document_footer ); 
	$_[0]->emit;
	}

sub _header_start
	{
	my( $self, $level ) = @_;

	if( $level )
		{		
		LEVEL: {
			if( @{ $self->{in_section} } and $self->{in_section}[0] >= $level )
				{
				my $tag = shift @{ $self->{in_section} };
				$self->add_xml_tag( "</sect$tag>\n" );
				redo LEVEL;
				}
			last LEVEL;
			}			
		
		my @parts = qw(title chapter section);
		push @parts, 'subsection' if $level > 1;
		
		@parts = map { $self->$_() } @parts;
		
		my $id = join '-', @parts;
		my $tag = qq|\n<sect$level id="$id">\n|;
	
		$self->add_xml_tag( $tag );
		unshift @{ $self->{in_section} }, $level;
		}
		
	$self->add_xml_tag( qq|<title>| );
	}
	
sub _header_end
	{
	my( $self, $level ) = @_;

	$self->add_xml_tag( "</title>\n" );
	}

sub start_head0     { $_[0]->_header_start( 0 ); }
sub end_head0       { $_[0]->_header_end( 0 );   }
	
sub end_head1       { $_[0]->_header_end( 1 );   }
sub start_head1     { 
	$_[0]->{section}++;
	$_[0]->{subsection} = 0;

	$_[0]->_header_start( 1 ); 
	}

sub end_head2       { $_[0]->_header_end( 2 );   }
sub start_head2     {
	$_[0]->{subsection}++;

	$_[0]->_header_start( 2 ); 
	}

sub start_head3     { $_[0]->_header_start( 3 ); }
sub end_head3       { $_[0]->_header_end( 3 );   }


sub end_non_code_text
	{
	my $self = shift;
	
	$self->make_curly_quotes;
	
	$self->emit;
	}

sub make_para
	{
	my( $self, $style, $para ) = @_;
	
	$self->add_xml_tag( '<para>' );
	$self->add_to_scratch( $para );
	$self->escape_and_emit;
	$self->add_xml_tag( "<\para>\n" );
	}
	
sub start_Para      
	{ 
	my $self = shift;
	
	$self->add_xml_tag( qq|<para>| );
	
	$self->add_to_scratch( "\x{25FE} " ) if $self->{in_item};
		
	$self->escape_and_emit;
	
	$self->{'in_para'} = 1; 
	}

sub end_Para        
	{ 
	my $self = shift;
	
	$self->add_xml_tag( "</para>\n" );
	
	$self->end_non_code_text;

	$self->{'in_para'} = 0;
	}

sub start_figure 	{ }

sub end_figure      { }
	
sub start_Verbatim 
	{ 
	$_[0]{'in_verbatim'} = 1;
	$_[0]->add_xml_tag( '<programlisting format="linespecific" id="I_programlisting3_tt28" xml:space="preserve">' );
	$_[0]->emit;
	}

sub end_Verbatim 
	{
	my $self = shift;
	
	# get rid of all but one trailing newline
	$self->escape_and_emit;
	
	$self->add_xml_tag( "</programlisting>\n" );	
		
	$self->{'in_verbatim'} = 0;
	}

sub _get_initial_item_type 
	{
	my $self = shift;
  
	my $type = $self->SUPER::_get_initial_item_type;
    
	$type;
	}


sub not_implemented { croak "Not implemented! " . (caller(1))[3] }

sub bullet_item_style { 'bullet item' }
sub start_item_bullet 
	{
	my( $self ) = @_;
	
	$self->{in_item} = 1;
	$self->{item_count}++;
	
	$self->start_Para;
	}

sub start_item_number { not_implemented() }
sub start_item_block  { not_implemented() }
sub start_item_text   { not_implemented() }

sub end_item_bullet
	{ 	
	my $self = shift;
	$self->end_Para;
	$self->{in_item} = 0;
	}	
sub end_item_number { not_implemented() }
sub end_item_block  { not_implemented() }
sub end_item_text   { not_implemented() }

sub start_over_bullet
	{ 
	my $self = shift;

	$self->{in_item_list} = 1;
	$self->{item_count}   = 0;
	}
sub start_over_text   { not_implemented() }
sub start_over_block  { not_implemented() }
sub start_over_number { not_implemented() }

sub end_over_bullet 
	{	
	my $self = shift;
	
	$self->end_non_code_text;
	
	$self->{in_item_list} = 0;	
	$self->{item_count}   = 0;
	$self->{last_thingy}  = 'item_list';
	$self->{scratch}      = '';
	}
sub end_over_text   { not_implemented() }
sub end_over_block  { not_implemented() }
sub end_over_number { not_implemented() }


sub end_B   { $_[0]->add_xml_tag( '</emphasis>' ); $_[0]->{in_B} = 0; }
sub start_B  
	{	
	$_[0]->add_xml_tag( '<emphasis>' ); 
	$_[0]->{in_B} = 1;
	}

sub end_C   { $_[0]->add_xml_tag( '</literal>' ); $_[0]->{in_C} = 0; }
sub start_C { $_[0]->add_xml_tag( '<literal moreinfo="none">' ); $_[0]->{in_C} = 1; }
	
sub end_I   { $_[0]->add_xml_tag( '</emphasize>' ) }
sub start_I { $_[0]->add_xml_tag( '<emphasize>' )  }

=pod

<footnote id="intermediateperl-CHP-3-FN2">
          <para>Although we don’t go into here, the <literal moreinfo="none">Module::CoreList</literal> module has the lists of
          which modules came with which versions of Perl, along with other
          historical data.</para>
        </footnote>

=cut

sub end_F   { $_[0]->add_xml_tag( '</filename>' ); $_[0]->{in_C} = 0; }
sub start_F { $_[0]->add_xml_tag( '<filename>' ); $_[0]->{in_C} = 1; }

sub start_M
	{	
	$_[0]{'module_flag'} = 1;
	$_[0]{'module_text'} = '';
	$_[0]->start_C;
	}

sub end_M
	{
	$_[0]->end_C;
	$_[0]{'module_flag'} = 0;
	}

sub start_N { }
sub end_N   { }

sub start_U { $_[0]->start_I }
sub end_U   { $_[0]->end_I   }

sub handle_text
	{
	my( $self, $text ) = @_;

	my $pad = $self->get_pad;
		
	$self->escape_text( \$text );
	$self->{$pad} .= $text;
	
	unless( $self->dont_escape )
		{
		$self->make_curly_quotes;
		$self->make_em_dashes;
		$self->make_ellipses;
		}
	}

sub dont_escape {
	my $self = shift;
	$self->{in_verbatim} || $self->{in_C}
	}
	
sub escape_text
	{
	my( $self, $text_ref ) = @_;
	
	$$text_ref =~ s/&/&amp;/g;
	$$text_ref =~ s/</&lt;/g;

	return 1;
	}

sub make_curly_quotes
	{
	my( $self ) = @_;
		
	my $text = $self->{scratch};
	
	require Tie::Cycle;
	
	tie my $cycle, 'Tie::Cycle', [ qw( &#x201C; &#x201D; ) ];

	1 while $text =~ s/"/$cycle/;
		
	# escape escape chars. This is escpaing them for InDesign
	# so don't worry about double escaping for other levels. Don't
	# worry about InDesign in the pod.
	$text =~ s/'/&#x2019;/g;
	
	$self->{'scratch'} = $text;
	
	return 1;
	}

sub make_em_dashes
	{		
	$_[0]->{scratch} =~ s/--/&#x2014;/g;	
	return 1;
	}

sub make_ellipses
	{		
	$_[0]->{scratch} =~ s/\Q.../&#x2026;/g;	
	return 1;
	}
	
BEGIN {
require Pod::Simple::BlackBox;

package Pod::Simple::BlackBox;

sub _ponder_Verbatim {
	my ($self,$para) = @_;
	DEBUG and print STDERR " giving verbatim treatment...\n";

	$para->[1]{'xml:space'} = 'preserve';
	foreach my $line ( @$para[ 2 .. $#$para ] ) 
		{
		$line =~ s/^\t//gm;
		$line =~ s/^(\t+)/" " x ( 4 * length($1) )/e
  		}
  
  # Now the VerbatimFormatted hoodoo...
  if( $self->{'accept_codes'} and
      $self->{'accept_codes'}{'VerbatimFormatted'}
  ) {
    while(@$para > 3 and $para->[-1] !~ m/\S/) { pop @$para }
     # Kill any number of terminal newlines
    $self->_verbatim_format($para);
  } elsif ($self->{'codes_in_verbatim'}) {
    push @$para,
    @{$self->_make_treelet(
      join("\n", splice(@$para, 2)),
      $para->[1]{'start_line'}, $para->[1]{'xml:space'}
    )};
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  } else {
    push @$para, join "\n", splice(@$para, 2) if @$para > 3;
    $para->[-1] =~ s/\n+$//s; # Kill any number of terminal newlines
  }
  return;
}

}

BEGIN {

# override _treat_Es so I can localize e2char
sub _treat_Es 
	{ 
	my $self = shift;

	require Pod::Escapes;	
	local *Pod::Escapes::e2char = *e2char_tagged_text;

	$self->SUPER::_treat_Es( @_ );
	}

sub e2char_tagged_text
	{
	package Pod::Escapes;
	
	my $in = shift;

	return unless defined $in and length $in;
	
	   if( $in =~ m/^(0[0-7]*)$/ )         { $in = oct $in; } 
	elsif( $in =~ m/^0?x([0-9a-fA-F]+)$/ ) { $in = hex $1;  }

	if( $NOT_ASCII ) 
	  	{
		unless( $in =~ m/^\d+$/ ) 
			{
			$in = $Name2character{$in};
			return unless defined $in;
			$in = ord $in; 
	    	}

		return $Code2USASCII{$in}
			|| $Latin1Code_to_fallback{$in}
			|| $FAR_CHAR;
		}
 
 	if( defined $Name2character_number{$in} and $Name2character_number{$in} < 127 )
 		{
 		return "&$in;";
 		}
	elsif( defined $Name2character_number{$in} ) 
		{
		# this needs to be fixed width because I want to look for
		# it in a negative lookbehind
		return sprintf '&#x%04x;', $Name2character_number{$in};
		}
	else
		{
		return '???';
		}
  
	}
}

=head1 TO DO


=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/Pod-WordML

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
