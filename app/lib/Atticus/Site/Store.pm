package Atticus::Site::Store;

our $VERSION = "0.01";

=head1 NAME

Atticus::Site::Store - handle the /store API

=cut

use v5.10;

use Atticus::Factory;
use Dancer ':syntax';
use JSON ();
use URI::file;

sub make_uri {
  my ( $host, $path ) = @_;
  my $u = URI::file->new_abs( join "/", "", @$path );
  $u->host($host);
  return $u;
}

prefix '/store' => sub {
  get '/*/**' => sub {
    my ( $host, $path ) = splat;
    my $u = make_uri( $host, $path );
    return { host => $host, path => $path, uri => "$u" };
  };

  put '/*/**' => sub {
    my $uri = make_uri(splat);
    my $md  = JSON->new->decode( request->body );
    return Atticus::Factory->store->put( $uri, $md );
  };
};

true;
