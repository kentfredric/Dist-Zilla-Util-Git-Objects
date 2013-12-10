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
  if ( $object->type ne 'commit' ) {
    require Carp;
    Carp::croak("Cannot resolve a tree from $desc");
  }
  my (@trees) = $object->get_header_strings('tree');
  return $self->get_tree_at( shift @trees );
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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
