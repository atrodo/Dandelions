package Stilts::Protocol::HTTP;

use strict;
use warnings;

use Moo;
use Carp;

extends 'Stilts::Protocol';

has headers => (
  is => 'ro',
);

use HTTP::HeaderParser::XS;

sub BUILD
{
  my $self = shift;
  
  $self->sock->reader(\&_headers_reader, $self);

  return 1;
}

sub _headers
{
  my $self = shift;
  my $headers_str = shift;

  croak "Request has already been read"
    if defined $self->headers;

  $self->{headers} = HTTP::HeaderParser::XS(\$headers_str);

  return 1;
}

sub _headers_reader
{
  my $self = shift;

  my $max_read = 10 * 1024;

  my $read_data = $self->sock->read($max_read);

  if (my $idx = index $$read_data, "\r\n\r\n")
  {
    $self->_headers(substr $$read_data, 0, $indx));
    $self->sock->push_back_read(substr $$read_data, $idx);
  }
  else
  {
    $self->sock->push_back_read($read_data);
  }

  return 1;
}

1;
