#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Test::More;
use Test::Differences;

use Atticus::Util::DataPath;

{
  my $dp = Atticus::Util::DataPath->new(
    paths => ["this.level.one", "this.level.two", "that", "this"] );
  eq_or_diff $dp->_tree,
   {that => { __TERM__ => '__TERM__' },
    this => {
      __TERM__ => '__TERM__',
      level    => {
        one => { __TERM__ => '__TERM__' },
        two => { __TERM__ => '__TERM__' } } }
   },
   "tree";

  my $got = {};
  $dp->visit(
    { bongo => "foo",
      that  => ["Hello!", "World"],
      this  => { beast => 3, level => { one => 1 } }
    },
    sub {
      my ( $val, $path ) = @_;
      push @{ $got->{$path} }, $val;
    }
  );

  eq_or_diff $got,
   {"that"           => ["Hello!", "World"],
    "this"           => [{ beast => 3, level => { one => 1 } }],
    "this.level.one" => [1]
   },
   "visit";
}

done_testing;
