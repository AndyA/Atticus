#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Fcntl ':mode';
use File::Temp;
use Getopt::Long;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use Path::Class;
use Scalar::Util qw( looks_like_number );
use Sys::Hostname;
use URI;
use URI::file;
use XML::LibXML qw( :libxml );

use constant CHUNK => 100;

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

for my $root (@ARGV) {
  scan($root);
}

sub scan {
  my $root = shift;
  if ( -f $root ) {
    update_file( file($root)->absolute );
    return;
  }
  my @queue = ($root);
  while (@queue) {
    my $next = pop @queue;
    my $dir  = dir($next)->absolute;
    say "Scanning $dir";
    my $store = file_to_store($dir);
    my $have  = get_obj($store);
    my $rkids = by_id( $have->{children} );
    my $lkids = dir_scan($dir);

    my @all    = uniq( keys %$rkids, keys %$lkids );
    my @delete = ();
    my @update = ();
    my @scan   = ();

    for my $kid ( sort { $b cmp $a } @all ) {
      my $lkid = $lkids->{$kid};
      my $rkid = $rkids->{$kid};

      unless ( defined $lkid ) {
        push @delete, $rkid;
        next;
      }

      if ( $lkid->{type} eq "dir" ) {
        push @queue, $lkid->{obj};
        next;
      }

      next unless $lkid->{type} eq "file";

      if ( need_update( $lkid, $rkid ) ) {
        push @update, $lkid;
      }
    }

    update_list( reverse @update );
    delete_list( reverse @delete );

  }
}

sub delete_list {
  delete_obj( $_->{_id} ) for @_;
}

sub delete_obj {
  my $uri       = shift;
  my $ua        = LWP::UserAgent->new;
  my $store_uri = store_uri($uri);
  say "Deleting $store_uri";
  my $resp = $ua->delete($store_uri);
  die $resp->status_line unless $resp->is_success;
}

sub update_list {
  my @obj = @_;

  my $ua = LWP::UserAgent->new;

  while (@obj) {
    my @work = splice @obj, 0, CHUNK;
    my $info = mediainfo( map { $_->{obj} } @work );
    my $data = parse_mi($info);
    for my $obj (@work) {
      my $mi = $data->{ $obj->{obj} } // {};

      my $rec = {
        stat      => $obj->{stat},
        mediainfo => $mi
      };

      my $store_uri = store_uri( $obj->{_id} );

      say "Updating $store_uri";
      my $req = HTTP::Request->new(
        PUT => $store_uri,
        [Content_Type => "application/json"],
        JSON->new->utf8->encode($rec)
      );
      my $resp = $ua->request($req);
      die $resp->status_line unless $resp->is_success;
    }
  }
}

sub need_update {
  my ( $lkid, $rkid ) = @_;
  return 1 unless defined $rkid;
  return 1
   unless $rkid->{stat}{mtime} == $lkid->{stat}{mtime}
   && $rkid->{stat}{size} == $lkid->{stat}{size};
  return;
}

sub uniq {
  my %seen = ();
  return grep { !$seen{$_}++ } @_;
}

sub dir_scan {
  my $dir  = shift;
  my $kids = {};

  for my $child ( $dir->children ) {
    next if $child->basename =~ /^\./;
    my $id = file_uri( $O{node}, $child );
    my $stat = obj_stat($child);
    next unless defined $stat;
    my $type = file_type( $stat->{mode} );
    $kids->{$id} = {
      _id  => "$id",
      obj  => $child,
      stat => $stat,
      type => $type
    };
  }

  return $kids;
}

sub by_id {
  my $obj = shift;
  return {} unless defined $obj;
  my $by_id = {};
  for my $o (@$obj) {
    die unless exists $o->{_id};
    $by_id->{ $o->{_id} } = $o;
  }
  return $by_id;
}

sub get_obj {
  my $uri  = shift;
  my $ua   = LWP::UserAgent->new;
  my $resp = $ua->get($uri);
  die $resp->status_line unless $resp->is_success;
  my $content = $resp->content;
  return unless length $content;
  return JSON->new->utf8->decode($content);
}

sub file_to_store {
  my $name = shift;
  return store_uri( file_uri( $O{node}, $name ) );
}

sub file_uri {
  my ( $host, $name ) = @_;
  my $u = URI::file->new_abs($name);
  $u->host($host);
  return $u;
}

sub store_uri {
  my $file_uri  = URI->new(shift);
  my $store_uri = URI->new( $O{store} );
  my ( undef, @path ) = $file_uri->path_segments;
  $store_uri->path_segments( "store", $file_uri->host, @path );
  return $store_uri;
}

sub parse_mi {
  my $doc = shift;

  my $data = {};
  for my $file ( $doc->findnodes('//Mediainfo/File') ) {
    my $stash = {};
    for my $track ( $file->findnodes('track') ) {
      my $type = lc $track->getAttribute('type');
      my $rec  = {};
      for my $node ( $track->getChildNodes ) {
        next unless $node->nodeType == XML_ELEMENT_NODE;
        my $key = to_camel( $node->nodeName );
        push @{ $rec->{$key} }, $node->textContent;
      }
      push @{ $stash->{$type} }, prepare_track($rec);
    }

    my $gen = delete $stash->{general};
    # next unless keys %$stash;

    $stash->{general} = $gen->[0];
    my $file_name = $gen->[0]{completeName};
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

sub prepare_track {
  my $rec   = shift;
  my $track = clean_mi_track($rec);

  if ( exists $track->{width} && exists $track->{height} ) {
    my ( $w, $h ) = @{$track}{ "width", "height" };
    $track->{area}                = $w * $h;
    $track->{orientation}         = orientation( $w, $h );
    $track->{computedAspectRatio} = $w / $h if $w && $h;
  }

  if ( exists $track->{completeName} ) {
    ( $track->{nameWords} = $track->{completeName} ) =~ s/[_\W]+/ /g;
  }

  # "language" is special to MongoDB
  if ( exists $track->{language} ) {
    $track->{languageName} = delete $track->{language};
  }

  return $track;
}

sub orientation {
  my ( $w, $h ) = @_;

  return "square" if $w == $h;
  return "landscape" if $w > $h;
  return "portrait";
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

sub file_type {
  my $mode = shift;

  return "unknown" unless defined $mode;

  return "file"   if S_ISREG($mode);
  return "dir"    if S_ISDIR($mode);
  return "link"   if S_ISLNK($mode);
  return "block"  if S_ISBLK($mode);
  return "char"   if S_ISCHR($mode);
  return "fifo"   if S_ISFIFO($mode);
  return "socket" if S_ISSOCK($mode);
  return "unknown";

}

sub obj_stat {
  my $obj = shift;

  my $stat = ();
  my @fld  = qw(
   dev  ino   mode  nlink uid     gid rdev
   size atime mtime ctime blksize blocks
  );
  my @data = stat $obj;
  return unless @data;
  @{$stat}{@fld} = @data;

  return $stat;
}

sub mediainfo {
  my @file = @_;
  my ( @oddball, @direct );

  for my $obj ( map { file($_)->absolute } @file ) {
    if   ( $obj =~ /[?*"<>]/ ) { push @oddball, $obj }
    else                       { push @direct,  $obj }
  }

  return run_mi(@direct) unless @oddball;

  # Make temp links to problematic files
  my $td   = File::Temp->newdir;
  my $next = 0;
  my (%oddmap);
  for my $obj (@oddball) {
    my ($ext) = $obj->basename =~ m{(\.[^.]+)$};
    my $tmp = file( $td, sprintf "%08d%s", $next++, $ext );
    symlink $obj, $tmp;
    $oddmap{$tmp} = $obj;
  }

  my $doc = run_mi( @direct, keys %oddmap );

  # Fix up XML
  for my $nd ( $doc->findnodes("//Mediainfo/File/track/Complete_name") ) {
    my $val  = $nd->textContent;
    my $orig = $oddmap{$val};
    next unless defined $orig;
    set_node_text( $nd, $orig );
    my $par = $nd->parentNode();
    for my $fnd ( $par->findnodes("Folder_name") ) {
      set_node_text( $fnd, $orig->parent );
    }
    for my $nnd ( $par->findnodes("File_name") ) {
      set_node_text( $nnd, $orig->basename );
    }
  }

  return $doc;
}

sub set_node_text {
  my ( $nd, $txt ) = @_;
  $nd->removeChildNodes;
  $nd->addChild( XML::LibXML::Text->new($txt) );
}

sub run_mi {
  my @file = @_;
  my $xml = run_cmd( 'mediainfo', '--Full', '--Output=XML', @file );
  return XML::LibXML->load_xml( string => $xml );
}

sub run_cmd {
  open my $fh, '-|', @_;
  my $out = do { local $/; <$fh> };
  close $fh;
  return $out;
}
