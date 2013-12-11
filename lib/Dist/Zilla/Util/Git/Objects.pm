use strict;
use warnings;

package Dist::Zilla::Util::Git::Objects;
BEGIN {
  $Dist::Zilla::Util::Git::Objects::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Objects::VERSION = '0.001000';
}

# ABSTRACT: Object oriented interface to map C<SHA1>s.

use Moose;
use Try::Tiny;
use Scalar::Util qw(blessed);
use MooseX::LazyRequire;


has git   => ( is => ro =>, isa => Object =>, lazy_build    => 1 );
has zilla => ( is => ro =>, isa => Object =>, lazy_required => 1 );
has typemap => ( is => ro =>, isa => HashRef => lazy_build => 1 );

sub _build_git {
  my ($self) = @_;
  require Dist::Zilla::Util::Git::Wrapper;
  return Dist::Zilla::Util::Git::Wrapper->new( zilla => $self->zilla );
}

sub _build_typemap {
  my ($self) = @_;
  return {
    'commit' => 'Dist::Zilla::Util::Git::Objects::Commit',
    'tag'    => 'Dist::Zilla::Util::Git::Objects::Tag',
    'tree'   => 'Dist::Zilla::Util::Git::Objects::Tree',
    'blob'   => 'Dist::Zilla::Util::Git::Objects::Blob',
  };
}

sub _inflate_type {
  my ( $self, $type, $rev ) = @_;
  if ( not exists $self->typemap->{$type} ) {
    require Carp;
    Carp::croak("type $type does not exist in the typemap");
  }
  my $typeclass = $self->typemap->{$type};
  require Module::Runtime;
  Module::Runtime::require_module($typeclass);
  return $typeclass->new(
    sha1 => $rev,
    git  => $self->git
  );
}

sub _object_exists {
  my ( $self, $object ) = @_;
  my $ok;
  try {
    $self->git->cat_file( '-e', $object );
    $ok = 1;
  }
  catch {
    if ( not ref $_ ) {
      die $_;
    }
    if ( not blessed $_ ) {
      die $_;
    }
    if ( not $_->isa('Git::Wrapper::Exception') ) {
      die $_;
    }
    if ( $_->status == 1 ) {
      undef $ok;
      return;
    }
    die $_;
  };
  return 1 if $ok;
  return;
}

sub _rev_parse {
  my ( $self, $desc ) = @_;
  my $ok;
  my $ref;
  try {
    ($ref) = $self->git->rev_parse( '--verify', '-q', $desc );
    $ok = 1;
  }
  catch {
    if ( not ref $_ ) {
      die $_;
    }
    if ( not blessed $_ ) {
      die $_;
    }
    if ( not $_->isa('Git::Wrapper::Exception') ) {
      die $_;
    }
    if ( $_->status == 1 ) {
      undef $ok;
      undef $ref;
      return;
    }
    die $_;
  };
  return $ref if $ok;
  return;

}


sub get_object {
  my ( $self, $desc ) = @_;
  my $rev;
  return unless defined( $rev = $self->_rev_parse($desc) );
  return unless $self->_object_exists($rev);
  my ($type) = $self->git->cat_file( '-t', $rev );
  return $self->_inflate_type( $type, $rev );
}


sub get_commit_at {
  my ( $self, $desc ) = @_;
  my $object = $self->get_object($desc);
  return unless $object;
  if ( $object->type eq 'tag' ) {
    my (@obj) = $object->get_header_strings('object');
    return $self->get_commit_at( shift @obj );
  }
  if ( $object->type eq 'commit' ) {
    return $object;
  }
  require Carp;
  Carp::croak( sprintf q[Cannot resolve a commit from %s (type = %s)], $desc, $object->type );
}


sub get_tree_at {
  my ( $self, $desc ) = @_;
  my $object = $self->get_object($desc);
  return unless $object;
  if ( $object->type eq 'tag' ) {
    my (@tags) = $object->get_header_strings('object');
    return $self->get_tree_at( shift @tags );
  }
  if ( $object->type eq 'tree' ) {
    return $object;
  }
  if ( $object->type eq 'commit' ) {
    my (@trees) = $object->get_header_strings('tree');
    return $self->get_tree_at( shift @trees );
  }
  require Carp;
  Carp::croak( sprintf q[Cannot resolve a tree from %s (type = %s)], $desc, $object->type );
}


sub get_tree_at_path {
  my ( $self, $desc, $path ) = @_;
  if ( not defined $path or not length $path ) {
    return $self->get_tree_at($desc);
  }
  if ( $path !~ qr[/] ) {
    my $tree = $self->get_tree_at($desc);
    if ( my $entry = $tree->entry_named($path) ) {
      return $self->get_tree_at( $entry->sha1 );
    }
    return;
  }
  my (@tokens) = split qr[/], $path;
  my $rootnode = shift @tokens;
  my $root     = $self->get_tree_at($desc);
  if ( my $entry = $root->entry_named( $tokens[0] ) ) {
    return $self->get_tree_at_path( $entry->sha1, join q[/], @tokens );
  }
  return;
}


sub get_blob_at {
  my ( $self, $commit, $path ) = @_;
  my (@tokens) = split qr{/}, $path;
  my ($filename) = pop @tokens;
  my $tree;
  if ( not @tokens ) {
    ( $tree, ) = $self->get_tree_at($commit);
  }
  else {
    ( $tree, ) = $self->get_tree_at_path( $commit, join q[/], @tokens );
  }
  return unless defined $tree;
  if ( my ($entry) = $tree->entry_named($filename) ) {
    my ($object) = $self->get_object( $entry->sha1 );
    if ( $object->type ne 'blob' ) {
      require Carp;
      Carp::confess("Child `$filename` is not a blob");
    }
    return $object;
  }
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Objects - Object oriented interface to map C<SHA1>s.

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

    my $o = Dist::Zilla::Util::Git::Objects->new(
        zilla => $self->zilla
    );
    my $b = Dist::Zilla::Util::Git::Branches->new(
        zilla => $self->zilla
    );
    my $commit = $o->get_commit( $b->get_branch('master')->sha1 );
    print "Last commit message is" . join q[\n] , @{ $commit->object_content };

    my $tree  = $o->get_commit( $commit->get_header_string('tree' ) );

    for my $entry (@{ $tree->entries } ) {
        printf "%s %s\n", $entry->mode, $entry->filename;
    }

=head1 METHODS

=head2 C<get_object>

Resolve the given name to an object

    my $object = $dzugo->get_object('deadbeefc0ffee');

Can also resolve any rev that resolves to a commit

    my $object = $dzugo->get_object('master');

Though this is not recommended due to ambiguity potential.

    my $object = $dzugo->get_object( $b->get_branch('master')->sha1  );
    my $object = $dzugo->get_object( $b->get_tag('master')->sha1  );

=head2 C<get_commit_at>

Resolve a C<rev> to a commit.

This is only really useful in cases where C<rev> is possibly a resolvant for an annotated C<tag>.

Here, C<get_commit_at> will follow the annotated C<tag> to find the C<commit>.

So you should always use this method instead of calling C<get_object> directly if you're always
expecting to git a C<commit> back.

    my $o = $dzugo->get_object('1.2.0'); # Resolves to annotated tag

    my $o = $dzugo->get_commit_at('1.2.0'); # Annotated tag resolves to commit

=head2 C<get_tree_at>

Like C<get_commit_at>, this method will follow object pointers digging until it finds a C<tree> object.

So this means:

    ref → annotated tag → commit → tree →
    ref →                 commit → tree →
    ref →                          tree →

This is useful in cases where you expect a tree always.

    my $t = $dzguo->get_tree_at('master'); # masters tree

=head2 C<get_tree_at_path>

This Further extends upon the logic of C<get_tree_at> and will resolve tree objects
that are found at the given path at the given commit.

    my $t = $dzugo->get_tree_at('master', 'lib' );
    my $t = $dzugo->get_tree_at('master', 'lib/Dist' );
    my $t = $dzugo->get_tree_at('master', 'lib/Dist/Foo' );

Implementationwise, this invokes

    my $sha = $dzugo->get_tree_at('master')->sha1;

In order to dig down to a tree of some description based on the search term.

If the search term is already a tree ref, then it proceeds to do path traversal, returning undef
as soon as it can't proceed further, returning the tree at the given path.

Though, it will always resolve to a C<tree>

If you specified the path to a C<blob>, this will return C<undef>.

=head2 C<get_blob_at>

This method resolves a path to a blob ( which you will probably see as being a files contents ).

    my $blob = $dzugo->get_blob_at('master','.gitignore');
    my $blob = $dzugo->get_blob_at('master','lib/Foo.pm');

This is implemented in terms of

    my $tree =  $dzugo->get_blob_at('master','lib');
    my $entry = $tree->entry_named('Foo.pm');
    return $dzugo->get_object($entry);

But will fail if C<Foo.pm> is a tree instead of a blob.

Otherwise, if the path does not exist at the give commit, it will return undef.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
