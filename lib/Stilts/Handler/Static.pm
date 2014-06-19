package Stilts::Handler::Static;

use strict;
use warnings;

use Moo;
use Carp;

use autodie;
use FindBin;
use File::Spec;
use IO::File;
use Cwd qw/realpath/;

my $root = realpath("$FindBin::Bin");

with 'Stilts::Handler';

has path => (
  is => 'ro',
  required => 1,
  init_arg => 'Path',
  coerce => sub { realpath(File::Spec->catdir($root, $_[0])); },
);

sub process
{
  my $self = shift;

  my $env = shift;

  my $path = realpath( $self->path . $env->{REQUEST_URI} );

  $path = File::Spec->catfile($self->path, "index.html")
    if !defined $path || -d $path;

  if (-r $path)
  {
    my $file = IO::File->new($path);
    my $size = -s $path;
    return ['200', [ 'Content-Type' => 'text/html', 'Content-Length' => $size, ], $file ];
  }
  else
  {
    return ['404', [ 'Content-Type' => 'text/plain' ], [ "Not Found" ] ];
  }

  return ['500', ['Content-Type' => 'text/plain' ], [ 'Error' ]];;
}

1;
