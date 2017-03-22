package Atticus::Model::Store;

our $VERSION = "0.01";

=head1 NAME

Atticus::Model::Store - access to MD store

=cut

use v5.10;

use Moose;
use Moose::Util::TypeConstraints;

has _store => (
  is      => 'ro',
  lazy    => 1,
  builder => '_b_store',
);

with qw(
 Atticus::Role::Mongo
);

sub _b_store { shift->db->collection("store") }

sub put {
  my ( $self, $uri, $md ) = @_;
  $self->_store->save( { _id => $uri, md => $md }, );
  return { status => "OK" };
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
