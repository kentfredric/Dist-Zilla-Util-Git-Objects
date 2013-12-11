use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Tree::Entry;

# ABSTRACT: An abstract representation of an entry in a Tree object

use Moose;

=head1 SYNOPSIS

This module only represents a lightweight container for a BLOB or TREE,
or a line in output of:

    git cat-file -p $TREESHA

As such, to get the actual content of one of these entries, you will still
need to do:

    $git_objects->get_object( $entry->sha1 ); # Could return a Blob or Tree

=cut

=attr C<mode>

=attr C<sha1>

=attr C<name>

=attr C<git>

=cut

has mode => ( isa => Str    => is => ro => required => 1 );
has sha1 => ( isa => Str    => is => ro => required => 1 );
has name => ( isa => Str    => is => ro => required => 1 );
has git  => ( isa => Object => is => ro => required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;
1;

