use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Role::Headers;

# ABSTRACT: A role for object types that have headers

use Moose::Role;

has 'object_headers' => ( isa => HashRef  =>, lazy_build => 1, is => ro => );
has 'object_content' => ( isa => ArrayRef =>, lazy_build => 1, is => ro => );

requires 'raw_content';

sub _build_object_headers {
  my ($self)  = @_;
  my (@lines) = ( @{ $self->raw_content } );
  my $headers = {};
  my $current_header;
  while (@lines) {
    last if $lines[0] eq q[];
    if ( $lines[0] =~ /\A [ ] .* \z/msx ) {
      push @{ $headers->{$current_header} }, $lines[0];
      shift @lines;
      next;
    }
    if ( $lines[0] =~ /\A (\S+) [ ] .* \z/msx ) {
      $current_header = $1;
      $headers->{$current_header} = [] unless exists $headers->{$current_header};
      push @{ $headers->{$current_header} }, $lines[0];
      shift @lines;
      next;
    }
    require Carp;
    Carp::croak("No header parse rule matched $lines[0]");
  }
  return $headers;
}

sub _build_tag_content {
  my ($self)  = @_;
  my (@lines) = ( @{ $self->raw_content } );
  while (@lines) {
    last if $lines[0] eq q[];
    shift @lines;
  }
  shift @lines;
  return \@lines;
}

sub has_header {
  my ( $self, $header ) = @_;
  return unless exists $self->object_headers->{$header};
  return 1;
}

=method C<get_header>

Returns a list  of array refs of headers with this name:

Examples:

    tag foo

    my (@items) = ->get_header('tag');

    \@items == [ [ 'tag' ] ]


    gpgsig foo
     bar baz
     quux doo

    my (@items) = ->get_header('gpgsig');
    \@items == [ ['foo','bar baz', 'quux doo' ] ]


    parent foo
    parent bar

    my (@items) = ->get_header('parent');
    \@items == [ ['foo'], ['bar' ] ];


=cut

sub get_header {
  my ( $self, $header ) = @_;
  if ( not $self->has_header($header) ) {
    require Carp;
    Carp::croak(qq[This object does not have the header `$header`]);
  }
  my @out;
  my $current;
  for my $line ( @{ $self->object_headers->{$header} } ) {
    if ( $line =~ /\A $header [ ] (.+) \z/msx ) {
      push @out, $current if defined $current;
      $current = ["$1"];
      next;
    }
    if ( $line =~ /\A [ ] (.+) \z/msx ) {
      push @{$current}, "$1";
      next;
    }
    require Carp;
    Carp::confess("Parse error in headers, $line did not match a rule");
  }
  push @out, $current;
  return @out;
}

=method C<get_header_strings>

Returns a list of headers with this name as strings

Examples:

    tag foo

    my (@items) = ->get_header('tag');

    \@items == [ 'tag' ]


    gpgsig foo
     bar baz
     quux doo

    my (@items) = ->get_header('gpgsig');
    \@items == [ "foo\nbar baz\nquux doo" ]


    parent foo
    parent bar

    my (@items) = ->get_header('parent');
    \@items == [ 'foo', 'bar' ];


=cut

sub get_header_strings {
  my ( $self, $header ) = @_;
  my (@headers) = $self->get_header($header);
  my @out;
  for my $header (@headers) {
    push @out, join qq[\n], @{$header};
  }
  return @out;
}

no Moose::Role;

1;

