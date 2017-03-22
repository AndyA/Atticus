#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Getopt::Long;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Path::Class;
use Scalar::Util qw( looks_like_number );
use Sys::Hostname;
use URI::file;
use XML::LibXML qw( :libxml );

use constant USAGE => <<EOT;
Syntax: $0 [options] <dir> ...

Options:
    -h, --help     See this text
    -s, --store    Base URI of store
    -n, --node     Our hostname
EOT

my %O = (
  help  => undef,
  store => "http://localhost/store/",
  node  => hostname,
);

GetOptions(
  "h|help"    => \$O{help},
  "s|store:s" => \$O{store},
  "n|node:s"  => \$O{node},
) or die USAGE;

say USAGE and exit if $O{help};
@ARGV or die USAGE;

my $info = mediainfo(@ARGV);
my $data = parse_mi($info);
# print JSON->new->pretty->canonical->encode($data);

my $ua = LWP::UserAgent->new;
while ( my ( $file, $md ) = each %$data ) {
  my $id = file_id( $O{node}, $file );
  my $store_uri = URI->new( $O{store} );
  my ( undef, @path ) = $id->path_segments;
  $store_uri->path_segments( "store", $id->host, @path );
  say $store_uri;
  my $req = HTTP::Request->new(
    PUT => $store_uri,
    [Content_Type => "application/json"],
    JSON->new->encode( { mediainfo => $md } )
  );
  my $resp = $ua->request($req);
  die $resp->status_line unless $resp->is_success;
}

sub file_id {
  my ( $host, $name ) = @_;
  my $u = URI::file->new_abs($name);
  $u->host($host);
  return $u;
}

sub parse_mi {
  my $doc = shift;

  my $data = {};
  for my $file ( $info->findnodes('//Mediainfo/File') ) {
    my $stash = {};
    for my $track ( $file->findnodes('track') ) {
      my $type = lc $track->getAttribute('type');
      my $rec  = {};
      for my $node ( $track->getChildNodes ) {
        next unless $node->nodeType == XML_ELEMENT_NODE;
        my $key = to_camel( $node->nodeName );
        push @{ $rec->{$key} }, $node->textContent;
      }
      push @{ $stash->{$type} }, clean_mi_track($rec);
    }

    my $gen = delete $stash->{general};
    next unless keys %$stash;

    $stash->{general} = $gen->[0];
    my $file_name = $gen->{completeName};
    $data->{$file_name} = $stash;
  }

  return $data;
}

sub clean_mi_value {
  my $vals = shift;

  # Favour any regular numbers
  for my $val (@$vals) {
    return 0 + $val if looks_like_number($val);
  }

  # Failing that choose the shortest value
  my @v = sort { length $a <=> length $b } sort @$vals;

  return $v[0];
}

sub clean_mi_track {
  my $rec = shift;
  return { map { $_ => clean_mi_value( $rec->{$_} ) } keys %$rec };
}

sub to_camel {
  my $name = shift;
  return "ID" if "ID" eq uc $name;
  my ( $head, @tail ) = split /_+/, $name;
  return join "", lcfirst $head, map ucfirst, @tail;
}

sub mediainfo {
  my @file = map { file($_)->absolute } @_;
  my $xml = run_cmd( 'mediainfo', '--Full', '--Output=XML', @file );
  return XML::LibXML->load_xml( string => $xml );
}

sub run_cmd {
  open my $fh, '-|', @_;
  my $out = do { local $/; <$fh> };
  close $fh;
  return $out;
}
