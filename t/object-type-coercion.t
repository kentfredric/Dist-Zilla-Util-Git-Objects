
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
  my ($tip_object) = $objects->get_object($tip);
  ok( defined $tip_object,                                         "Tip commit returns defined" );
  ok( ref $tip_object,                                             "Tip commit returns ref" );
  ok( $tip_object->isa('Dist::Zilla::Util::Git::Objects::Commit'), "Tip commit isa Commit" );
  my $tree;
  for my $line ( @{ $tip_object->pretty_content } ) {
    if ( $line =~ /\Atree (\S+)\z/ ) {
      note "Got tree $1";
      $tree = $1;

      my ($tree_object) = $objects->get_object($tree);
      ok( defined $tree_object,                                       "Tip Tree is defined" );
      ok( ref $tree_object,                                           "Tip Tree is ref" );
      ok( $tree_object->isa('Dist::Zilla::Util::Git::Objects::Tree'), "Tip Tree isa Tree" );

      for my $treeline ( @{ $tree_object->pretty_content } ) {
        if ( $treeline =~ /^.*?[ ]blob[ ](\S+)\s+(.+)/ ) {
          my ( $sha, $name ) = ( $1, $2 );
          note "$sha => $name";

          my ($file_object) = $objects->get_object($sha);
          ok( defined $file_object,                                       "Tree blob is defined" );
          ok( ref $file_object,                                           "Tree blob is ref" );
          ok( $file_object->isa('Dist::Zilla::Util::Git::Objects::Blob'), "Tree blob isa Blob" );
        }
      }
    }
  }

  my $non_tip = $tip;
  $non_tip =~ tr/0123456789abcdef/fedcba987654321/;
  note "Non Tip = $non_tip";
  is( $objects->get_object($non_tip), undef, "Non-Tip commit does not exist" );
};

is( $excp, undef, 'No exceptions from doing object mangling' ) or diag $excp;

done_testing;

