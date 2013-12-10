use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::Git::Objects::Commit;

# ABSTRACT: A Commit Object

use Moose;

with 'Dist::Zilla::Util::Git::Objects::Role::Object';

sub type { return 'commit' }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

