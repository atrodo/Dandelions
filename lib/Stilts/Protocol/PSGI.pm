package Stilts::Protocol::PSGI;

use strict;
use warnings;

use Moo;
use Carp;

with 'Stilts::Protocol';

has headers => (
  is => 'ro',
);

use HTTP::HeaderParser::XS;
use HTTP::Message::PSGI;
use HTTP::Response;
use Plack::Response;

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

  $self->{headers} = HTTP::HeaderParser::XS->new(\$headers_str);

  return 1;
}

sub _headers_reader
{
  my $self = shift;

  my $max_read = 10 * 1024;

  my $read_data = $self->sock->read($max_read);

  if (my $idx = index $$read_data, "\r\n\r\n")
  {
    $self->_headers(substr $$read_data, 0, $idx);
    $self->sock->push_back_read(substr $$read_data, $idx);

    $self->sock->reader(\&_service_reader, $self);
  }
  else
  {
    $self->sock->push_back_read($read_data);
  }

  return 1;
}

# We don't actually read anything, we just process the routing
sub _service_reader
{
  my $self = shift;

  my $read_data = $self->sock->read(0);

  $self->service->process($self);

  $self->sock->reader(\&_headers_reader, $self);

  return 1;
}

sub psgi_response
{
  my $self = shift;

  my $res = res_from_psgi([@_]);

  $res->protocol("HTTP/1.0");
  $self->sock->write($res->as_string);
  $self->sock->close;
}

1;
