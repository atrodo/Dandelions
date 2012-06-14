package Stilts::Service;

use strict;
use warnings;

use Moo::Role;
use Carp;

requires 'process';

around BUILDARGS => sub
{
  my $orig = shift;
  my $self = shift;

  my $args = $orig->( $self, @_ );

  return $args->{options};
};

1;
