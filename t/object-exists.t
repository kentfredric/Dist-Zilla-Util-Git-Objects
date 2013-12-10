
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 12/07/13 06:28:57 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Simple functionality test.

use Path::Tiny qw(path);

my $tempdir = Path::Tiny->tempdir;
my $repo    = $tempdir->child('git-repo');
my $home    = $tempdir->child('homedir');

local $ENV{HOME}                = $home->absolute->stringify;
local $ENV{GIT_AUTHOR_NAME}     = 'A. U. Thor';
local $ENV{GIT_AUTHOR_EMAIL}    = 'author@example.org';
local $ENV{GIT_COMMITTER_NAME}  = 'A. U. Thor';
local $ENV{GIT_COMMITTER_EMAIL} = 'author@example.org';

$repo->mkpath;
my $file = $repo->child('testfile');

use Dist::Zilla::Util::Git::Wrapper;
use Git::Wrapper;
use Test::Fatal qw(exception);

my $git = Git::Wrapper->new($repo);
my $wrapper = Dist::Zilla::Util::Git::Wrapper->new( git => $git );

sub report_ctx {
  my (@lines) = @_;
  note explain \@lines;
}
my $tip;

my $excp = exception {
  $wrapper->init();
  $file->touch;
  $wrapper->add("$file");
  $wrapper->commit( '-m', 'Test Commit' );
  ( $tip, ) = $wrapper->rev_parse('HEAD');
  $wrapper->tag( '0.1.0', $tip );
  $wrapper->tag( '0.1.1', $tip );
};

is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or diag $excp;

use Dist::Zilla::Util::Git::Objects;
my $objects = Dist::Zilla::Util::Git::Objects->new( git => $git );

$excp = exception {
  note "Tip = $tip";
  is( $objects->_object_exists($tip), 1, "Tip commit exists" );
  my $non_tip = $tip;
  $non_tip =~ tr/0123456789abcdef/fedcba987654321/;
  note "Non Tip = $non_tip";
  is( $objects->_object_exists($non_tip), undef, "Non-Tip commit does not exist" );
};

is( $excp, undef, 'No exceptions from simply testing object existence' ) or diag $excp;

done_testing;

