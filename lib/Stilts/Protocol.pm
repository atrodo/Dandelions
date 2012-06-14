package Stilts::Protocol;

use strict;
use warnings;

use Moo;
use Carp;

has sock => (
  is       => 'rw',
  required => 1,
);

has route => (
  is       => 'rw',
  required => 1,
);

has server => (
  is       => 'rw',
  required => 1,
);

1;
