use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Tree::Entry;
BEGIN {
  $Dist::Zilla::Util::Git::Objects::Tree::Entry::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Objects::Tree::Entry::VERSION = '0.001000';
}

# ABSTRACT: An abstract representation of an entry in a Tree object

use Moose;



has mode => ( isa => Str    => is => ro => required => 1 );
has sha1 => ( isa => Str    => is => ro => required => 1 );
has name => ( isa => Str    => is => ro => required => 1 );
has git  => ( isa => Object => is => ro => required => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Objects::Tree::Entry - An abstract representation of an entry in a Tree object

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This module only represents a lightweight container for a BLOB or TREE,
or a line in output of:

    git cat-file -p $TREESHA

As such, to get the actual content of one of these entries, you will still
need to do:

    $git_objects->get_object( $entry->sha1 ); # Could return a Blob or Tree

=head1 ATTRIBUTES

=head2 C<mode>

=head2 C<sha1>

=head2 C<name>

=head2 C<git>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
