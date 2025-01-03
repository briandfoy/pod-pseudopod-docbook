package Pod::PseudoPod::DocBook;
use strict;
use base 'Pod::PseudoPod';

use warnings;
no warnings;

use subs qw(DEBUG);

use Carp;

our $VERSION = '0.191';

sub DEBUG () { 0 }

=encoding utf8

=head1 NAME

Pod::PseudoPod::DocBook - Turn Pod into DocBook

=head1 SYNOPSIS

	use Pod::PseudoPod::DocBook;

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

=item * add_xml_tag

=cut

sub add_xml_tag
	{
	my( $self, $stuff ) = @_;

	$self->add_to_pad( $stuff );
	$self->emit;
	}

=item * add_data

=cut

sub add_data
	{
	my( $self, $stuff ) = @_;

	$self->add_to_pad( $stuff );
	$self->escape_and_emit;
	}

=item * escape_and_emit

=cut

sub escape_and_emit
	{
	my( $self ) = @_;

	my $pad = $self->get_pad;

	$self->{$pad} =~ s/\s+\z//;

	$self->{$pad} =~ s/&/&amp;/g;
	$self->{$pad} =~ s/</&lt;/g;
	$self->{$pad} =~ s/>/&gt;/g;

	$self->emit;
	}

=item * add_to_pad

=cut

sub add_to_pad
	{
	my( $self, $stuff ) = @_;
	my $pad = $self->get_pad;
	$self->{$pad} .= $stuff;
	}

=item * clear_pad

=cut

sub clear_pad
	{
	my( $self ) = @_;

	my $pad = $self->get_pad;
	$self->{$pad} = '';
	}

=item * set_title

=cut

sub set_title   {  $_[0]->{title} = $_[1] }

=item * set_chapter

=cut

sub set_chapter {  $_[0]->{chapter} = $_[1] }

=item * title

=cut

sub title      { $_[0]->{title}      }

=item * chapter

=cut

sub chapter    { $_[0]->{chapter}    }

=item * section

=cut

sub section    { $_[0]->{section}    }

=item * subsection

=cut

sub subsection { $_[0]->{subsection} }

=item * document_header

=cut

sub document_header
	{
	my $string = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE chapter PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN"
	"http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd">
<!-- created by brian's private converter -->
XML

	my $id = join '-', $_[0]->title, $_[0]->chapter;

	my $filename = $_[0]->{source_filename};
	$_[0]->{root_tag} = do {
		    if( $filename =~ /app/ ) { 'appendix' }
		elsif( $filename =~ /ch00/ ) { 'preface'  }
		else                         { 'chapter'  }
		};

	$string .= <<"XML";
<$_[0]->{root_tag} id="$id">

XML
	}

=item * document_footer

=cut

sub document_footer
	{
	my $string = '';

	foreach my $section (  @{ $_[0]->{in_section} } )
		{
		$string .= "</sect$section>\n";
		}

	$string .= <<"XML";
</$_[0]->{root_tag}>
XML
	}

=back

=head2 The Pod::Simple mechanics

Everything else is the same stuff from C<Pod::Simple>.

=over 4

=cut

use Data::Dumper;

=item * new

=cut

sub new {
	my $self = $_[0]->SUPER::new();
	$self->{accept_targets}{table}++;
	$self->{accept_targets}{figure}++;
	$self;
	}

=item * emit

Transfer text from the pad to the output

=cut

sub emit
	{
	my $pad = $_[0]->get_pad;
	print {$_[0]->{'output_fh'}} $_[0]->{$pad};
	$_[0]->clear_pad;
	return;
	}

=item * get_pad

Return the name of the pad to use based on current state

=cut

sub get_pad
	{
	# flow elements first
	   if( $_[0]{module_flag}   ) { 'scratch'     }
	elsif( $_[0]{in_U}      )     { 'url_text'    }
	elsif( $_[0]{in_L}      )     { 'link_text'   }
	elsif( $_[0]{in_R}      )     { 'ref_text'    }
	elsif( $_[0]{in_figure} )     { 'figure_text' }
	# then block elements
	# finally the default
	else                          { 'scratch'     }
	}

=item * start_Document

Start the document

=cut

sub start_Document
	{
	$_[0]->{in_section} = [];
	$_[0]->add_to_pad( $_[0]->document_header );
	$_[0]->emit;
	}

=item * end_Document

End the document

=cut

sub end_Document
	{
	$_[0]->add_to_pad( $_[0]->document_footer );
	$_[0]->emit;
	}

=item * _header_start

=cut

sub _header_start
	{
	my( $self, $level ) = @_;

	$self->{in_header} = 1;
	if( $level )
		{
		LEVEL: {
			if( eval { @{ $self->{in_section} } } and $self->{in_section}[0] >= $level )
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

=item * _header_end

=cut

sub _header_end
	{
	my( $self, $level ) = @_;
	$self->{in_header} = 0;

	$self->add_xml_tag( "</title>\n" );
	}

=item * start_head0

=item * start_head1

=item * start_head2

=item * start_head3

=item * start_head4

=item * end_head0

=item * end_head1

=item * end_head2

=item * end_head3

=item * end_head4

Start or end a heading level

=cut

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


=item * end_non_code_text

=cut

sub end_non_code_text
	{
	my $self = shift;

	$self->make_curly_quotes;

	$self->emit;
	}

=item * make_para

=cut

sub make_para
	{
	my( $self, $style, $para ) = @_;

	$self->add_xml_tag( '<para>' );
	$self->add_to_pad( $para );
	$self->escape_and_emit;
	$self->add_xml_tag( "<\para>\n\n" );
	}

=item * start_Para

=cut

sub start_Para
	{
	my $self = shift;

	return if $self->{in_figure};

	$self->add_xml_tag( qq|<para>| );

	$self->escape_and_emit;

	$self->{'in_para'} = 1;
	}

=item * end_Para

=cut

sub end_Para
	{
	my $self = shift;

	return if $self->{in_figure};

	$self->add_xml_tag( "</para>\n\n" );

	$self->end_non_code_text;

	$self->{'in_para'} = 0;
	}

=item * start_Verbatim

=cut

sub start_Verbatim
	{
	$_[0]{'in_verbatim'} = 1;
	my $sequence = ++$_[0]{'verbatim_sequence'};
	my $chapter  = $_[0]->chapter;

	$_[0]->add_xml_tag( qq|\n<programlisting format="linespecific" id="I_programlisting_${chapter}_tt${sequence}" xml:space="preserve">| );
	$_[0]->emit;
	}

=item * end_Verbatim

=cut

sub end_Verbatim
	{
	my $self = shift;

	# get rid of all but one trailing newline
	#$self->escape_and_emit;

	$self->add_xml_tag( "</programlisting>\n\n" );

	$self->{'in_verbatim'} = 0;
	}

=item * _get_initial_item_type

=cut

sub _get_initial_item_type
	{
	my $self = shift;

	my $type = $self->SUPER::_get_initial_item_type;

	$type;
	}


=item * not_implemented

=cut

sub not_implemented { croak "Not implemented! " . (caller(1))[3] }

=item * in_item_list

=cut

sub in_item_list { scalar @{ $_[0]->{list_levels} } }

=item * add_list_level_item

=cut

sub add_list_level_item {
	${ $_[0]->{list_levels} }[-1]{item_count}++;
	}

=item * is_first_list_level_item

=cut

sub is_first_list_level_item {
	${ $_[0]->{list_levels} }[-1]{item_count} == 0;
	}

=item * start_list_level

=cut

sub start_list_level
	{
	my $self = shift;

	push @{ $self->{list_levels} }, { item_count => 0 };
	}

=item * end_list_level

=cut

sub end_list_level
	{
	my $self = shift;

	pop @{ $self->{list_levels} };
	}

=item * start_item_bullet

=cut

sub start_item_bullet
	{
	my( $self ) = @_;

	#print STDERR Dumper($self->{list_levels}), "\n"; use Data::Dumper;
	$self->add_xml_tag( "</listitem>\n\n" )
		unless $self->is_first_list_level_item;
	$self->add_list_level_item;
	$self->add_xml_tag( "<listitem>\n" );
	$self->start_Para;
	}

=item * start_item_number

=cut

sub start_item_number {
	$_[0]->add_xml_tag( '<listitemnumber>' )
	}

=item * start_item_block

=cut

sub start_item_block  { $_[0]->add_xml_tag( '<listitemblock>' ) }

=item * start_item_text

=cut

sub start_item_text   { $_[0]->add_xml_tag( '<listitemtext>' ) }

=item * end_item_bullet

=cut

sub end_item_bullet
	{
	my $self = shift;
	$self->end_Para;
#	$self->add_to_pad( "</listitem>\n\n" );
	$self->{in_item} = 0;
	}

=item * end_item_number

=cut

sub end_item_number { $_[0]->add_xml_tag( '</listitemnumber>' ) }

=item * end_item_block

=cut

sub end_item_block  { $_[0]->add_xml_tag( '</listitemblock>' ) }

=item * end_item_text

=cut

sub end_item_text   { $_[0]->add_xml_tag( '</listitemtext>' ) }

=item * start_over_bullet

=cut

sub start_over_bullet
	{
	my $self = shift;
	if( $self->{saw_exercises} ) {
		$self->add_xml_tag( qq(\n<orderedlist continuation="restarts" inheritnum="ignore" numeration="arabic">\n\n) );
		}
	else {
		$self->add_xml_tag( qq(<itemizedlist>) )
		}

	$self->start_list_level;

	}

=item * start_over_text

=cut

sub start_over_text   { $_[0]->add_xml_tag( '<itemizedlist-text>' ) }

=item * start_over_block

=cut

sub start_over_block  { $_[0]->add_xml_tag( '<itemizedlist-block>' ) }

=item * start_over_number

=cut

sub start_over_number { $_[0]->add_xml_tag( '<itemizedlist-number>' ) }

=item * end_over_bullet

=cut

sub end_over_bullet
	{
	my $self = shift;

	$self->{last_thingy}  = 'item_list';
	$self->end_non_code_text;
	$self->add_xml_tag( "</listitem>\n\n" );

	my $tag = $self->{saw_exercises} ? 'orderedlist' : 'itemizedlist';

	$self->add_to_pad( "</$tag>\n\n" );
	$self->end_list_level;
	$self->emit;
	}

=item * end_over_text

=cut

sub end_over_text   {
	$_[0]->add_xml_tag( '</listitemtext>' );
	$_[0]->add_xml_tag( '</itemizedlisttext>' )
	}

=item * end_over_block

=cut

sub end_over_block  {
	$_[0]->add_xml_tag( '</listitemblock>' );
	$_[0]->add_xml_tag( '</itemizedlistblock>' )
	}

=item * end_over_number

=cut

sub end_over_number {
	$_[0]->add_xml_tag( '</listitemnumber>' );
	$_[0]->add_xml_tag( '</itemizedlistnumber>' )
	}

=item * start_figure

=cut

sub start_figure 	{
	my( $self, $flags ) = @_;
	$self->{in_figure} = 1;
	$self->{figure_title} = $flags->{title};

	my $pad = $self->get_pad;
	}

=begin comment

   <figure id="FIG3-1_ID_HERE">
     <title>FIG3-1_TITLE_HERE</title>
     <mediaobject>
       <imageobject role="web">
         <imagedata fileref="figs/web/lnp5_0301.png" format="PNG"/>
       </imageobject>
     </mediaobject>
   </figure>

=end comment

=cut

=item * end_figure

=cut

sub end_figure {
	my( $self, $flags ) = @_;

	my $id = $self->title . '-' . $self->chapter .
		'-FIGURE-' . ++$_[0]{'figure_count'};
	my $pad = $self->get_pad;
	my $filename = $self->{$pad};
	$self->clear_pad;
	my( $format ) = map { uc } ($filename =~ /(p(?:ng|df))\z/ig);

	$self->add_xml_tag( <<"XML"	);
   <figure id="$id">
     <title>$self->{figure_title}</title>
     <mediaobject>
       <imageobject role="web">
         <imagedata fileref="$filename" format="$format"/>
       </imageobject>
     </mediaobject>
   </figure>

XML

	$self->{figure_title} = 0;
	$self->{in_figure} = 0;
	}

=item * start_table

=cut

sub start_table {
	my( $self, $flags ) = @_;

	my $id = $self->title . '-' . $self->chapter .
		'-TABLE-' . ++$_[0]{'table_count'};
	$self->add_xml_tag(
		qq|<table id="$id">\n| .
		qq|<title>$flags->{'title'}</title>\n| .
		qq|<tgroup cols="2">\n|
		);
	}

=item * end_table

=cut

sub end_table      {
	$_[0]{'in_bodyrow'} = 0;
	$_[0]->{rows} = 0;
	$_[0]->add_xml_tag( "</tbody></tgroup></table>\n" );
	}

=item * start_headrow

=cut

sub start_headrow  {
	$_[0]{'in_headrow'} = 1;
	$_[0]{'in_bodyrow'} = 0;
	}

=item * start_bodyrows

=cut

sub start_bodyrows {
	$_[0]{'in_bodyrow'} = 1;
	}

=item * start_row

=cut

sub start_row {
	$_[0]->{rows}++;

	   if( $_[0]->{rows} == 1 ) { $_[0]->add_xml_tag( qq(<thead>\n) ) }

	$_[0]->add_xml_tag( qq(<row>\n) );
	}

=item * end_row

=cut

sub end_row {
	$_[0]->add_xml_tag( qq(</row>\n) );
	if( $_[0]{'in_bodyrow'} and $_[0]{'in_headrow'} ) { $_[0]->add_xml_tag( qq(</thead>\n<tbody>\n) ); $_[0]{'in_headrow'}=0; }
	}

=item * start_cell

Start a table cell

=cut

sub start_cell { $_[0]->add_xml_tag( qq(\t<entry align="left" valign="top">) ) }

=item * end_cell

End a table cell

=cut

sub end_cell   { $_[0]->add_xml_tag( qq(</entry>\n) ) }


=item * end_B

End a C<< B<> >> sequence

=cut

sub end_B   { $_[0]->add_xml_tag( '</command>' ); $_[0]->{in_B} = 0; }


=item * start_B

Start a C<< B<> >> sequence

=cut

sub start_B
	{
	$_[0]->add_xml_tag( '<command>' );
	$_[0]->{in_B} = 1;
	}

=item * end_C

=cut

sub end_C   { $_[0]->add_xml_tag( '</literal>' ); $_[0]->{in_C} = 0; }

=item * start_C

=cut

sub start_C { $_[0]->add_xml_tag( '<literal moreinfo="none">' ); $_[0]->{in_C} = 1; }

=item * end_F

=cut

sub end_F   { $_[0]->add_xml_tag( '</filename>' ) }

=item * start_F

=cut

sub start_F { $_[0]->add_xml_tag( '<filename>' )  }

=item * end_I

=cut

sub end_I   { $_[0]->add_xml_tag( '</emphasis>' ) }

=item * start_I

=cut

sub start_I { $_[0]->add_xml_tag( '<emphasis>' )  }

=pod

<footnote id="intermediateperl-CHP-3-FN2">
          <para>Although we don’t go into here, the <literal moreinfo="none">Module::CoreList</literal> module has the lists of
          which modules came with which versions of Perl, along with other
          historical data.</para>
        </footnote>

<ulink role="orm:hideurl"
url="http://www.guardian.co.uk/film/2006/
sep/22/londonfilmfestival2006.londonfilmfestival">Automavision</ulink>
=cut

=item * end_L

=cut

sub end_L   {
	my $pad = $_[0]->get_pad;
	my $text = $_[0]->{$pad};
	$_[0]->clear_pad;
	my $link = do {
		if( $text =~ /\A(perl[a-z0-9]+)\z/ ) { "http://perldoc.perl.org/$1.html" }
		};

	$_[0]->add_xml_tag( qq|<ulink role="orm:hideurl" url="$link">| );
	$_[0]->add_to_pad( $text );
	$_[0]->add_xml_tag( '</ulink>' );
	$_[0]->emit;
	$_[0]->{in_L} = 0;
	}

=item * start_L

=cut

sub start_L {
	$_[0]->emit;
	$_[0]->{in_L} = 1;
	}

=item * start_M

=cut

sub start_M
	{
	$_[0]{'module_flag'} = 1;
	$_[0]{'module_text'} = '';
	$_[0]->start_C;
	}

=item * end_M

=cut

sub end_M
	{
	$_[0]->end_C;
	$_[0]{'module_flag'} = 0;
	}

=item * end_N

=cut

sub end_N   { $_[0]->add_xml_tag( '</para></footnote>' ); $_[0]->{in_N} = 0; }

=item * start_N

=cut

sub start_N {
	$_[0]->{in_N} = 1;
	my $id = join '-', 'footnote', $_[0]->title, $_[0]->chapter, $_[0]->{footnote}++;
	$_[0]->add_xml_tag( qq|<footnote id="$id"><para>| );
	}

=item * start_R

=cut

sub start_R { $_[0]->emit; $_[0]->{in_R} = 1 }

=item * end_R

=cut

sub end_R   {
	my $pad = $_[0]->get_pad;
	my $text = $_[0]->{$pad};
	$_[0]->clear_pad;

	$text = do {
		if( $text =~ /\A\d+\z/ )        { sprintf '%02d', $text }
		elsif( $text =~ /\A[abc]\z/i ) { "app" . lc($text) }
		elsif( $text =~ /a\.(\d+)/i )  { "appa-$1" }
		};

	my $link = join '-', $_[0]->title, $text;
	$_[0]->add_xml_tag( qq|<xref linkend="$link" />| );
	$_[0]->emit;
	$_[0]->{in_R} = 0;
	}

=item * start_T

=cut

sub start_T { $_[0]->add_xml_tag( '<citetitle>' )  }

=item * end_T

=cut

sub end_T   { $_[0]->add_xml_tag( '</citetitle>' ) }

=item * start_U

=cut

sub start_U { $_[0]->emit; $_[0]->{in_U} = 1 }

=item * end_U

=cut

sub end_U   {
	my $pad = $_[0]->get_pad;
	my $text = $_[0]->{$pad};
	$_[0]->clear_pad;

	$_[0]->add_xml_tag( qq|<ulink url="$text" />| );
	$_[0]->emit;
	$_[0]->{in_U} = 0;
	}

=item * handle_text

=cut

sub handle_text
	{
	my( $self, $text ) = @_;

	if( $text eq 'Exercises' ) {
	#print STDERR "In exercises\n";
		$self->{saw_exercises} = 1;
		}
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

=item * dont_escape

Return true if we are in a context where we shouldn't escape text

=cut

sub dont_escape {
	my $self = shift;
	$self->{in_verbatim} || $self->{in_C}
	}

=item * escape_text

Escape C<&> and C<< < >>

=cut

sub escape_text
	{
	my( $self, $text_ref ) = @_;

	$$text_ref =~ s/&/&amp;/g;
	$$text_ref =~ s/</&lt;/g;

	return 1;
	}

=item * make_curly_quotes

=cut

sub make_curly_quotes
	{
	my( $self ) = @_;

	my $pad  = $self->get_pad;
	my $text = $self->{$pad};

	require Tie::Cycle;

	tie my $cycle, 'Tie::Cycle', [ qw( &#x201C; &#x201D; ) ];

	1 while $text =~ s/"/$cycle/;

	# escape escape chars. This is escpaing them for InDesign
	# so don't worry about double escaping for other levels. Don't
	# worry about InDesign in the pod.
	$text =~ s/'/&#x2019;/g;

	$self->{$pad} = $text;

	return 1;
	}

=item * make_em_dashes

Take the pad value and translate -- to em dashes

=cut

sub make_em_dashes
	{
	my( $self ) = @_;
	my $pad  = $self->get_pad;
	$_[0]->{$pad} =~ s/--/&#x2014;/g;
	return 1;
	}

=item * make_ellipses

Take the pad value and translate ... to ellipses

=cut

sub make_ellipses
	{
	my( $self ) = @_;
	my $pad  = $self->get_pad;
	$self->{$pad} =~ s/\Q.../&#x2026;/g;
	return 1;
	}

BEGIN {
use Pod::Simple::BlackBox;

package Pod::Simple::BlackBox;

no warnings qw(redefine);

sub _ponder_Verbatim {
	my ($self,$para) = @_;
	DEBUG() and print STDERR " giving verbatim treatment...\n";

	$para->[1]{'xml:space'} = 'preserve';
	foreach my $line ( @$para[ 2 .. $#$para ] ) {
		$line =~ s/\A(\t|  )//gm;
		$line =~ s/\A(\t+)/" " x ( 4 * length($1) )/e;
		warn
			sprintf(
				"%s: tab in code listing! [%s]",
				$self->chapter,
				$line
				) if $line =~ /\t/;
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

=item * e2char_tagged_text

=cut

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

=back

=head1 TO DO


=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/pod-pseudopod-docbook

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

sub _ponder_paragraph_buffer {

  # Para-token types as found in the buffer.
  #   ~Verbatim, ~Para, ~end, =head1..4, =for, =begin, =end,
  #   =over, =back, =item
  #   and the null =pod (to be complained about if over one line)
  #
  # "~data" paragraphs are something we generate at this level, depending on
  # a currently open =over region

  # Events fired:  Begin and end for:
  #                   directivename (like head1 .. head4), item, extend,
  #                   for (from =begin...=end, =for),
  #                   over-bullet, over-number, over-text, over-block,
  #                   item-bullet, item-number, item-text,
  #                   Document,
  #                   Data, Para, Verbatim
  #                   B, C, longdirname (TODO -- wha?), etc. for all directives
  #

  my $self = $_[0];
  my $paras;
  return unless @{$paras = $self->{'paras'}};
  my $curr_open = ($self->{'curr_open'} ||= []);

  DEBUG() > 10 and print "# Paragraph buffer: <<", pretty($paras), ">>\n";

  # We have something in our buffer.  So apparently the document has started.
  unless($self->{'doc_has_started'}) {
    $self->{'doc_has_started'} = 1;

    my $starting_contentless;
    $starting_contentless =
     (
       !@$curr_open
       and @$paras and ! grep $_->[0] ne '~end', @$paras
        # i.e., if the paras is all ~ends
     )
    ;
    DEBUG() and print "# Starting ",
      $starting_contentless ? 'contentless' : 'contentful',
      " document\n"
    ;

    $self->_handle_element_start('Document',
      {
        'start_line' => $paras->[0][1]{'start_line'},
        $starting_contentless ? ( 'contentless' => 1 ) : (),
      },
    );
  }

  my($para, $para_type);
  while(@$paras) {
    last if @$paras == 1 and
      ( $paras->[0][0] eq '=over' or $paras->[0][0] eq '~Verbatim'
        or $paras->[0][0] eq '=item' )
    ;
    # Those're the three kinds of paragraphs that require lookahead.
    #   Actually, an "=item Foo" inside an <over type=text> region
    #   and any =item inside an <over type=block> region (rare)
    #   don't require any lookahead, but all others (bullets
    #   and numbers) do.

# TODO: winge about many kinds of directives in non-resolving =for regions?
# TODO: many?  like what?  =head1 etc?

    $para = shift @$paras;
    $para_type = $para->[0];

    DEBUG() > 1 and print "Pondering a $para_type paragraph, given the stack: (",
      $self->_dump_curr_open(), ")\n";

    if($para_type eq '=for') {
      next if $self->_ponder_for($para,$curr_open,$paras);
    } elsif($para_type eq '=begin') {
      next if $self->_ponder_begin($para,$curr_open,$paras);
    } elsif($para_type eq '=end') {
      next if $self->_ponder_end($para,$curr_open,$paras);
    } elsif($para_type eq '~end') { # The virtual end-document signal
      next if $self->_ponder_doc_end($para,$curr_open,$paras);
    }


    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    if(grep $_->[1]{'~ignore'}, @$curr_open) {
      DEBUG() > 1 and
       print "Skipping $para_type paragraph because in ignore mode.\n";
      next;
    }
    #~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    # ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

    if($para_type eq '=pod') {
      $self->_ponder_pod($para,$curr_open,$paras);
    } elsif($para_type eq '=over') {
      next if $self->_ponder_over($para,$curr_open,$paras);
    } elsif($para_type eq '=back') {
      next if $self->_ponder_back($para,$curr_open,$paras);
    } elsif($para_type eq '=row') {
      next if $self->_ponder_row_start($para,$curr_open,$paras);

    } elsif( $para_type eq '=headrow'){
    	$self->start_headrow;
    } elsif( $para_type eq '=bodyrows') {
    	$self->start_bodyrows;
    	}

    else {
      # All non-magical codes!!!

      # Here we start using $para_type for our own twisted purposes, to
      #  mean how it should get treated, not as what the element name
      #  should be.

      DEBUG() > 1 and print "Pondering non-magical $para_type\n";

      # In tables, the start of a headrow or bodyrow also terminates an
      # existing open row.
      if($para_type eq '=headrow' || $para_type eq '=bodyrows') {
        $self->_ponder_row_end($para,$curr_open,$paras);
      }

      # Enforce some =headN discipline
      if($para_type =~ m/^=head\d$/s
         and ! $self->{'accept_heads_anywhere'}
         and @$curr_open
         and $curr_open->[-1][0] eq '=over'
      ) {
        DEBUG() > 2 and print "'=$para_type' inside an '=over'!\n";
        $self->whine(
          $para->[1]{'start_line'},
          "You forgot a '=back' before '$para_type'"
        );
        unshift @$paras, ['=back', {}, ''], $para;   # close the =over
        next;
      }


      if($para_type eq '=item') {
        next if $self->_ponder_item($para,$curr_open,$paras);
        $para_type = 'Plain';
        # Now fall thru and process it.

      } elsif($para_type eq '=extend') {
        # Well, might as well implement it here.
        $self->_ponder_extend($para);
        next;  # and skip
      } elsif($para_type eq '=encoding') {
        # Not actually acted on here, but we catch errors here.
        $self->_handle_encoding_second_level($para);

        next;  # and skip
      } elsif($para_type eq '~Verbatim') {
        $para->[0] = 'Verbatim';
        $para_type = '?Verbatim';
      } elsif($para_type eq '~Para') {
        $para->[0] = 'Para';
        $para_type = '?Plain';
      } elsif($para_type eq 'Data') {
        $para->[0] = 'Data';
        $para_type = '?Data';
      } elsif( $para_type =~ s/^=//s
        and defined( $para_type = $self->{'accept_directives'}{$para_type} )
      ) {
        DEBUG() > 1 and print " Pondering known directive ${$para}[0] as $para_type\n";
      } else {
        # An unknown directive!
        DEBUG() > 1 and printf "Unhandled directive %s (Handled: %s)\n",
         $para->[0], join(' ', sort keys %{$self->{'accept_directives'}} )
        ;
        $self->whine(
          $para->[1]{'start_line'},
          "Unknown directive: $para->[0]"
        );

        # And maybe treat it as text instead of just letting it go?
        next;
      }

      if($para_type =~ s/^\?//s) {
        if(! @$curr_open) {  # usual case
          DEBUG() and print "Treating $para_type paragraph as such because stack is empty.\n";
        } else {
          my @fors = grep $_->[0] eq '=for', @$curr_open;
          DEBUG() > 1 and print "Containing fors: ",
            join(',', map $_->[1]{'target'}, @fors), "\n";

          if(! @fors) {
            DEBUG() and print "Treating $para_type paragraph as such because stack has no =for's\n";

          #} elsif(grep $_->[1]{'~resolve'}, @fors) {
          #} elsif(not grep !$_->[1]{'~resolve'}, @fors) {
          } elsif( $fors[-1][1]{'~resolve'} ) {
            # Look to the immediately containing for

            if($para_type eq 'Data') {
              DEBUG() and print "Treating Data paragraph as Plain/Verbatim because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
              $para->[0] = 'Para';
              $para_type = 'Plain';
            } else {
              DEBUG() and print "Treating $para_type paragraph as such because the containing =for ($fors[-1][1]{'target'}) is a resolver\n";
            }
          } else {
            DEBUG() and print "Treating $para_type paragraph as Data because the containing =for ($fors[-1][1]{'target'}) is a non-resolver\n";
            $para->[0] = $para_type = 'Data';
          }
        }
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if($para_type eq 'Plain') {
        $self->_ponder_Plain($para);
      } elsif($para_type eq 'Verbatim') {
        $self->_ponder_Verbatim($para);
      } elsif($para_type eq 'Data') {
        $self->_ponder_Data($para);
      } else {
        die "\$para type is $para_type -- how did that happen?";
        # Shouldn't happen.
      }

      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      $para->[0] =~ s/^[~=]//s;

      DEBUG() and print "\n", Pod::Simple::BlackBox::pretty($para), "\n";

      # traverse the treelet (which might well be just one string scalar)
      $self->{'content_seen'} ||= 1;
      $self->_traverse_treelet_bit(@$para);
    }
  }

  return;
}

1;
