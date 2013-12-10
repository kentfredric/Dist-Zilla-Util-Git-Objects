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

sub type { 'tree' }

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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
