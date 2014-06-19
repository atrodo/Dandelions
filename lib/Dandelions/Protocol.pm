package Dandelions::Protocol;

use strict;
use warnings;

use Moo::Role;
use Carp;

use Scalar::Util qw/blessed/;

requires "new_socket";

has handler => (
  is       => 'ro',
  required => 1,
  isa => sub {
    croak "Must pass a Dandelions::Handler to Dandelions::Protocol"
      unless blessed($_[0]) && $_[0]->does("Dandelions::Handler");
  },
);

1;
