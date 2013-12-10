use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Role::Object;

# ABSTRACT: Base behavior for all git objects

use Moose::Role;

has sha1           => ( isa => Str             =>, is => ro =>, required   => 1 );
has git            => ( isa => Object          =>, is => ro =>, required   => 1 );
has size           => ( isa => Str             =>, is => ro =>, lazy_build => 1 );
has raw_content    => ( isa => 'ArrayRef[Str]' =>, is => ro =>, lazy_build => 1 );
has pretty_content => ( isa => 'ArrayRef[Str]' =>, is => ro =>, lazy_build => 1 );

requires 'type';

sub _build_size {
  my ($self) = @_;
  my (@out) = $self->git->cat_file( '-s', $self->sha1 );
  return shift @out if @out == 1;
  require Carp;
  Carp::croak( '!=1 Results from cat-file -s ' . $self->sha1 );
}

sub _build_raw_content {
  my ($self) = @_;
  return [ $self->git->cat_file( $self->type, $self->sha1 ) ];
}

sub _build_pretty_content {
  my ($self) = @_;
  return [ $self->git->cat_file( '-p', $self->sha1 ) ];
}

no Moose::Role;

1;

