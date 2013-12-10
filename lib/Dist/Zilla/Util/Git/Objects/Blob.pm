use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Blob;

# ABSTRACT: A Blob Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';

sub type { return 'blob' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

