use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Tag;

# ABSTRACT: An Annotated Tag Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';
with 'Dist::Zilla::Util::Git::Objects::Role::Headers';

sub type { return 'tag' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

