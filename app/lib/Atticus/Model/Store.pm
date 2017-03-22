package Atticus::Model::Store;

our $VERSION = "0.01";

=head1 NAME

Atticus::Model::Store - access to MD store

=cut

use v5.10;

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

sub _b_store { shift->db->collection("store") }

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
  $self->_store->save($data);
}

sub _mkpath {
  my ( $self, $uri ) = @_;

  my $obj = $self->_get_meta($uri);
  if ( defined $obj ) {
    die "$uri is not a dir"
     unless $obj->{type} eq "dir";
    return;
  }

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

  return $self->_get_meta($uri);
}

sub put {
  my ( $self, $uri, $md ) = @_;

  $self->_mkparent($uri);
  $self->_save( $uri, "file", { md => $md } );
  return { status => "OK" };
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
