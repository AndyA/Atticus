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

  # TODO index weights
  $store->ensure_index(
    { map { $_ => "text" }
       qw(
       mediainfo.audio.title
       mediainfo.general.comapplequicktimekeywords
       mediainfo.general.comment
       mediainfo.general.copyright
       mediainfo.general.description
       mediainfo.general.fileName
       mediainfo.general.movieMore
       mediainfo.general.movieName
       mediainfo.general.originalSourceFormName
       mediainfo.general.title
       mediainfo.general.titleMoreInfo
       mediainfo.general.trackName
       mediainfo.general.nameWords
       )
    },
    { name => "fullText" }
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

sub _save {
  my ( $self, $uri, $type, $rec ) = @_;

  my $data = dclone( $rec // {} );

  $data->{_id}  = "$uri";
  $data->{type} = $type;
  my $parent = $self->_parent($uri);
  $data->{parent} = "$parent" if defined $parent;

  if ( defined( my $mi = $data->{mediainfo} ) ) {
    my %tags = %$mi;
    delete $tags{general};
    $data->{tags} = [sort keys %tags];
  }

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

  $self->_mkparent($uri);
  $self->_save( $uri, "file", $data );
  return { status => "OK" };
}

sub delete {
  my ( $self, $uri ) = @_;
  my $store = $self->_store;
  my $pat   = qr{^\Q$uri\E/};
  $store->remove( { _id => $uri } );    # document
  $store->remove( { _id => $pat } );    # in case of dir
  return { status => "OK" };
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
