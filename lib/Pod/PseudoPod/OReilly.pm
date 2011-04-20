package Pod::PseudoPod::DocBook::OReilly;
use strict;
use base 'Pod::PseudoPod::DocBook';

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.13';

=head1 NAME

Pod::PseudoPod::DocBook::OReilly - Turn Pod into O'Reilly's DocBook

=head1 SYNOPSIS

	use Pod::PseudoPod::DocBook::OReilly;

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


=cut

=back

=head1 TO DO


=head1 SEE ALSO

L<Pod::PseudoPod>, L<Pod::PseudoPod::DocBook>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/Pod-WordML

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
