package Atticus::Site::Store;

our $VERSION = "0.01";

=head1 NAME

Atticus::Site::Store - handle the /store API

=cut

use v5.10;

use Atticus::Factory;
use Dancer ':syntax';
use JSON ();
use URI;

sub make_uri {
  my $path = shift;
  my $host = shift @$path;
  my $u    = URI->new("file://");
  $u->host($host);
  $u->path_segments(@$path);
  return $u;
}

prefix '/store' => sub {
  get '/' => sub {
    return Atticus::Factory->store->get("/");    # special case
  };

  get '/**' => sub {
    my $uri = make_uri(splat);
    return Atticus::Factory->store->get($uri);
  };

  put '/**' => sub {
    my $uri = make_uri(splat);
    my $md  = JSON->new->utf8->decode( request->body );
    return Atticus::Factory->store->put( $uri, $md );
  };

  del '/**' => sub {
    my $uri = make_uri(splat);
    return Atticus::Factory->store->delete($uri);

  };
};

true;
