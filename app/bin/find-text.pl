#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Dancer qw( :script );
use Dancer::Plugin;
use Dancer::Plugin::Mango;
use JSON ();

register_hook 'database_connected';

my $stash = {};
my $db    = mango->db("atticus")->collection("store");
my $cur   = $db->find();
while ( my $doc = $cur->next ) {
  walk_rec(
    $doc,
    sub {
      my ( $val, @path ) = @_;
      return unless defined $val;
      return unless length($val) > 20;
      my @words = split /\s+/, $val;
      return unless @words > 5;
      my $key = join ".", @path;
      $stash->{$key} = $val
       unless exists $stash->{$key}
       && length( $stash->{$key} ) > length($val);
    }
  );
}

print JSON->new->pretty->canonical->encode($stash);

sub walk_node {
  my ( $rec, $cb, @path ) = @_;
  if ( ref $rec ) { walk_rec( $rec, $cb, @path ) }
  else            { $cb->( $rec, @path ) }
}

sub walk_rec {
  my ( $rec, $cb, @path ) = @_;
  die unless ref $rec;
  if ( "HASH" eq ref $rec ) {
    while ( my ( $key, $val ) = each %$rec ) {
      walk_node( $val, $cb, @path, $key );
    }
    return;
  }

  if ( "ARRAY" eq ref $rec ) {
    for my $val (@$rec) {
      walk_node( $val, $cb, @path );
    }
    return;
  }

  die "Can't handle ", ref $rec;
}
