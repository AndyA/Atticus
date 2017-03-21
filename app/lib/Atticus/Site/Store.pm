package Atticus::Site::Store;

use v5.10;

use URI::file;

use Dancer ':syntax';

our $VERSION = '0.01';

prefix '/store' => sub {
  get '/*/**' => sub {
    my ( $host, $path ) = splat;
    my $u = URI::file->new_abs( join "/", "", @$path );
    $u->host($host);
    return { uri => "$u" };
  };
};

true;
