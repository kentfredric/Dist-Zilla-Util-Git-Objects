use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Role::Object;
BEGIN {
  $Dist::Zilla::Util::Git::Objects::Role::Object::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Objects::Role::Object::VERSION = '0.001000';
}

# ABSTRACT: Base behavior for all git objects

use Moose;

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

sub pretty_content {
  my ($self) = @_;
  return [ $self->git->cat_file( '-p', $self->sha1 ) ];
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Objects::Role::Object - Base behavior for all git objects

=head1 VERSION

version 0.001000

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
