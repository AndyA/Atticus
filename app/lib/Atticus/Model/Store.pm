package Atticus::Model::Store;

our $VERSION = "0.01";

=head1 NAME

Atticus::Model::Store - access to MD store

=cut

use v5.10;

use Dancer qw( :syntax );

use Moose;
use Storable qw( dclone );
use URI;

has _store => (
  is      => 'ro',
  lazy    => 1,
  builder => '_b_store',
);

with qw(
 Atticus::Role::Mongo
);

sub _init_indexes {
  my ( $self, $store ) = @_;
  $store->ensure_index( { parent => 1 } );
  $store->ensure_index( { type   => 1 } );
  $store->ensure_index( { tags   => 1 } );

  $store->ensure_index( { "exif.location" => "2dsphere" } );

  my %ft = (
    "mediainfo.audio.title"                       => 10,
    "mediainfo.general.title"                     => 10,
    "mediainfo.general.comapplequicktimekeywords" => 5,
    "mediainfo.general.comment"                   => 5,
    "mediainfo.general.copyright"                 => 2,
    "mediainfo.general.description"               => 5,
    "mediainfo.general.fileName"                  => 1,
    "mediainfo.general.performer"                 => 4,
    "mediainfo.general.movieMore"                 => 3,
    "mediainfo.general.movieName"                 => 3,
    "mediainfo.general.originalSourceFormName"    => 3,
    "mediainfo.general.titleMoreInfo"             => 3,
    "mediainfo.general.trackName"                 => 1,
    "mediainfo.general.nameWords"                 => 4,
  );

  $store->ensure_index(
    { map { $_ => "text" } keys %ft },
    { name => "fullText", weights => \%ft }
  );
}

sub _b_store {
  my $self  = shift;
  my $store = $self->db->collection("store");
  $self->_init_indexes($store);
  return $store;
}

sub _parent {
  my ( $self, $uri ) = @_;
  my $puri = URI->new($uri);
  my @path = $puri->path_segments;
  return unless @path;
  pop @path;
  $puri->path_segments(@path);
  return $puri;
}

sub _get_meta {
  my ( $self, $uri ) = @_;
  return $self->_store->find_one( { _id => $uri }, { type => 1 } );
}

sub _get_loc {
  my ( $self, $info ) = @_;

  # Try to find the GPS position. It may well be that one of these
  # things implies the other anyway.

  return $info->{GPSPosition}
   if exists $info->{GPSPosition};

  return [$info->{GPSLatitude}, $info->{GPSLongitude}]
   if exists $info->{GPSLatitude} && exists $info->{GPSLongitude};

  return;
}

sub _decode_sfx_meta {
  my ( $self, $meta ) = @_;

  return unless defined $meta && length $meta;

  my $out = {};
  while ( $meta =~ s/^(\w)="(.*?)":\s*// ) {
    my ( $k, $v ) = ( $1, $2 );
    $out->{$k} = $v;
  }

  return if length $meta;
  return $out;
}

sub _valid_loc {
  my ( $self, $lat, $lon ) = @_;

  return if $lat == 0 && $lon == 0;
  return if $lat < -90  || $lat > 90;
  return if $lon < -180 || $lon > 180;
  return 1;
}

sub _augment_data {
  my ( $self, $rec ) = @_;
  my $data = dclone( $rec // {} );

  if ( defined( my $mi = $data->{mediainfo} ) ) {
    my %tags = %$mi;
    delete $tags{general};
    $data->{tags} = [sort keys %tags];
  }

  if ( defined( my $exif = $data->{exif} ) ) {
    my $loc = $self->_get_loc($exif);
    if ( defined $loc ) {
      my ( $lat, $lon ) = @$loc;
      if ( $self->_valid_loc( $lat, $lon ) ) {
        $exif->{location} = {
          type        => "Point",
          coordinates => [$lon, $lat] };
      }
    }

    if ( exists $exif->{Description} ) {
      my $meta = $self->_decode_sfx_meta( $exif->{Comment} )
       // $self->_decode_sfx_meta( $exif->{Description} );

      $exif->{MetaInfo} = $meta
       if defined $meta;
    }
  }

  return $data;
}

sub _save {
  my ( $self, $uri, $type, $rec ) = @_;

  my $data = $self->_augment_data($rec);

  $data->{_id}  = "$uri";
  $data->{type} = $type;
  my $parent = $self->_parent($uri);
  $data->{parent} = "$parent" if defined $parent;

  $self->_store->save($data);
}

sub _mkpath {
  my ( $self, $uri ) = @_;

  my $obj = $self->_get_meta($uri);
  return if defined $obj && $obj->{type} eq "dir";
  $self->_mkparent($uri);
  $self->_save( $uri, "dir" );
}

sub _mkparent {
  my ( $self, $uri ) = @_;
  my $parent = $self->_parent($uri);
  $self->_mkpath($parent) if defined $parent;
}

sub get {
  my ( $self, $uri ) = @_;

  my $store = $self->_store;

  # Special case: return a synthetic root object
  if ( "$uri" eq "/" ) {
    return {
      type     => "dir",
      children => $store->find( { parent => { '$exists' => 0 } },
        { type => 1, stat => 1 } )->sort( { _id => 1 } )->all
    };
  }

  my $obj = $store->find_one( { _id => $uri } );

  return $obj
   unless defined $obj && $obj->{type} eq "dir";

  $obj->{children}
   = $store->find( { parent => $uri }, { type => 1, stat => 1 } )
   ->sort( { _id => 1 } )->all;

  return $obj;
}

sub put {
  my ( $self, $uri, $data ) = @_;

  die if "$uri" eq "/";

  $self->_mkparent($uri);
  $self->_save( $uri, "file", $data );
  return { status => "OK" };
}

sub delete {
  my ( $self, $uri ) = @_;

  die if "$uri" eq "/";

  my $store = $self->_store;
  my $pat   = qr{^\Q$uri\E/};
  $store->remove( { _id => $uri } );    # document
  $store->remove( { _id => $pat } );    # in case of dir
  return { status => "OK" };
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
