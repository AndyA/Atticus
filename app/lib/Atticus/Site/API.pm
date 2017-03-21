package Atticus::Site::API;

use v5.10;

use Dancer ':syntax';

our $VERSION = '0.01';

prefix '/api' => sub {
  get '/' => sub {
    return {};
  };
};

true;
