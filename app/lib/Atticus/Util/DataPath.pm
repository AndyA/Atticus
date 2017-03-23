package Atticus::Util::DataPath;

our $VERSION = "0.01";

=head1 NAME

Atticus::Util::DataPath - handle dotted paths

=cut

use v5.10;

use Moose;

has paths => (
  is      => "ro",
  isa     => "ArrayRef",
  default => sub { [] },
);

has _tree => (
  is      => "ro",
  isa     => "HashRef",
  lazy    => 1,
  builder => "_b_tree",
);

sub _b_tree {
  my $self  = shift;
  my $paths = $self->paths;
  my $tree  = {};
  for my $path (@$paths) {
    my @part = split /\./, $path;
    my $nd = $tree;
    for my $key (@part) {
      $nd = $nd->{$key} //= {};
    }
    $nd->{__TERM__} = "__TERM__";
  }
  return $tree;
}

sub _visit {
  my ( $self, $obj, $cb, $nd, @path ) = @_;

  return unless defined $nd;

  if ( ref $obj && "ARRAY" eq ref $obj ) {
    $self->_visit( $_, $cb, $nd, @path ) for @$obj;
    return;
  }

  my %keys = %$nd;
  if ( exists $keys{__TERM__}
    && defined $keys{__TERM__}
    && !ref $keys{__TERM__}
    && "__TERM__" eq $keys{__TERM__} ) {
    delete $keys{__TERM__};
    $cb->( $obj, join ".", @path );
  }

  return unless ref $obj;

  if ( "HASH" eq ref $obj ) {
    for my $key ( sort keys %keys ) {
      next unless exists $obj->{$key};
      $self->_visit( $obj->{$key}, $cb, $nd->{$key}, @path, $key );
    }
  }
}

sub visit {
  my ( $self, $obj, $cb ) = @_;
  my $tree = $self->_tree;
  $self->_visit( $obj, $cb, $tree );
}

no Moose;
__PACKAGE__->meta->make_immutable;
