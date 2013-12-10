use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Commit;
BEGIN {
  $Dist::Zilla::Util::Git::Objects::Commit::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Util::Git::Objects::Commit::VERSION = '0.001000';
}

# ABSTRACT: A Commit Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';
with 'Dist::Zilla::Util::Git::Objects::Role::Headers';

sub type { return 'commit' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::Git::Objects::Commit - A Commit Object

=head1 VERSION

version 0.001000

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
