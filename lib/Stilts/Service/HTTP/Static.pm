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
use IO::File;
use Cwd qw/realpath/;

my $root = realpath("$FindBin::Bin/..");

sub process
{
  my $self = shift;

  my $protocol = shift;

  my $headers = $protocol->headers;

  my $path = File::Spec->canonpath( $root . $self->path . $headers->getURI() );
  ($path) = File::Spec->no_upwards( $path );

  $path = "$path/index.html"
    if -d $path;

  if (-r $path)
  {
    $protocol->psgi_response('200', [ 'Content-Type' => 'text/html' ], IO::File->new($path) );
  }
  else
  {
    $protocol->psgi_response('404', [ 'Content-Type' => 'text/plain' ], [ "Not Found" ] );
  }

  return 1;
}

1;
