package Stilts::Protocol;

use strict;
use warnings;

use Moo::Role;
use Carp;

use Scalar::Util qw/blessed/;

has sock => (
  is       => 'ro',
  required => 1,
  isa => sub {
    croak "Must pass a Stilts::Socket to Stilts::Protocol"
      unless blessed($_[0]) && $_[0]->isa("Stilts::Socket");
  },
);

has handler => (
  is       => 'ro',
  required => 1,
  isa => sub {
    croak "Must pass a Stilts::Handler to Stilts::Protocol"
      unless blessed($_[0]) && $_[0]->does("Stilts::Handler");
  },
);

1;
