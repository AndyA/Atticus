package Atticus::Factory;

our $VERSION = "0.01";

=head1 NAME

Atticus::Factory - Make objects on demand

=cut

use v5.10;

use MooseX::Singleton;
use Moose::Util::TypeConstraints;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Mango;

# Bodge to allow Dancer::Plugin::MongoDB to work
register_hook 'database_connected';

use Atticus::Model::Store;

has store => (
  is      => "ro",
  isa     => "Atticus::Model::Store",
  lazy    => 1,
  builder => "_b_store"
);

sub _b_store {
  my $self = shift;
  return Atticus::Model::Store->new(
    mongo   => mongo,
    db_name => "atticus"
  );
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
