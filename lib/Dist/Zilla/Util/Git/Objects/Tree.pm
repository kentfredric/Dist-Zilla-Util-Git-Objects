use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Tree;

# ABSTRACT: A Tree Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';

sub type { return 'tree' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

