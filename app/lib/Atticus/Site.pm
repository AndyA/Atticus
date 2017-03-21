package Atticus::Site;

use v5.10;

use Dancer ':syntax';

our $VERSION = '0.01';

get '/' => sub {
  template 'index';
};

true;
