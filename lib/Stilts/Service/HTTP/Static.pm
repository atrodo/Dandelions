package Stilts::Service::HTTP::Static;

use strict;
use warnings;

use Moo;
use Carp;

with 'Stilts::Service';

has path => (
  is => 'ro',
  required => 1,
  init_arg => 'Path',
);

use autodie;
use FindBin;
use File::Spec;

sub process
{
  my $self = shift;

  my $protocol = shift;

  my $headers = $protocol->headers;

  my $path = File::Spec->no_upwards( $FindBin::Bin . $self->path . $headers->getURI() );

  $path = $path . "index.html"
    if -d $path;

  $protocol->psgi_response('200', [ 'Content-Type' => 'text/plain' ], [ "hello"]);
  if (-r $path)
  {
    # Slurp
    open my $fh, "<", "$path";
    my $file = do { local $/; <$fh> };

    # And send
    $protocol->sock->write($file);
  }
  else
  {
  }

  return 1;
}

1;
