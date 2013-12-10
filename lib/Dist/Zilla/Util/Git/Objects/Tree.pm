use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Tree;
BEGIN {
  $Dist::Zilla::Util::Git::Objects::Tree::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Objects::Tree::VERSION = '0.001000';
}

# ABSTRACT: A Tree Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';

sub type { return 'tree' }


has entries => ( isa => ArrayRef =>, is => ro => lazy_build => 1 );


sub entry_named {
  my ( $self, $name ) = @_;
  return grep { $_->name eq $name } @{ $self->entries };
}

sub _mk_entry {
  my ( $self, $mode, $name, $sha1 ) = @_;
  require Dist::Zilla::Util::Git::Objects::Tree::Entry;
  return Dist::Zilla::Util::Git::Objects::Tree::Entry->new(
    mode => $mode,
    name => $name,
    sha1 => $sha1,
    git  => $self->git,
  );
}

sub _build_entries {
  my ($self) = @_;
  my $content = join qq[\n], @{ $self->raw_content };
  my @out;
  while ( length $content ) {
    my $mode = do {
      my $space_pos = index( $content, q[ ] );
      my $rval = substr( $content, 0, $space_pos );
      substr( $content, 0, $space_pos + 1, "" );
      $rval;
    };
    my $filename = do {
      my $null_pos = index( $content, chr(0) );
      my $rval = substr( $content, 0, $null_pos );
      substr( $content, 0, $null_pos + 1, "" );
      $rval;
    };
    my $sha1 = do {
      my $sha_size = 20;
      my $rval = unpack( 'H*', substr( $content, 0, $sha_size ) );
      substr( $content, 0, $sha_size, "" );
      $rval;
    };
    push @out, $self->_mk_entry( $mode, $filename, $sha1 );
  }
  return \@out;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Objects::Tree - A Tree Object

=head1 VERSION

version 0.001000

=head1 METHODS

=head2 C<entry_named>

Returns any entries matching the name.

    my ( @entries ) = $tree->entry_named('foo.txt');

=head1 ATTRIBUTES

=head2 C<entries>

All the entries from the tree object.

An array of L<< C<Dist::Zilla::Util::Git::Objects::Tree::Entry>|Dist::Zilla::Util::Git::Objects::Tree::Entry >>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
