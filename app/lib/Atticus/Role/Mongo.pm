package Atticus::Role::Mongo;

use Moose::Role;

=head1 NAME

Atticus::Role::Mongo - Mango handle etc

=cut

has db_name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has mongo => (
  is       => 'ro',
  required => 1,
);

has db => (
  is      => 'ro',
  lazy    => 1,
  builder => '_b_db',
);

sub _b_db {
  my $self = shift;
  return $self->mongo->db( $self->db_name );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
