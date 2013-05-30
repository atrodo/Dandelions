package Stilts::Config;

use strict;
use warnings;

use Moo;
use Carp;
use JSON;
use autodie;

use Data::Dumper;
use Scalar::Util qw/blessed/;

my $default_config = decode_json do { local $/; <DATA> };
close DATA;

has _config_handle => (
  is => 'ro',
);

has config => (
  is => 'rw',
  default => sub { $default_config },
);

around BUILDARGS => sub
{
  my $orig = shift;
  my $class = shift;

  my $handle;

  if ( blessed($_[0]) && $_[0]->isa("IO::Handle") )
  {
    $handle = shift;
  }

  my $args = $orig->( $class, @_ );

  $args->{_config_handle} = $handle;

  return $args;
};

sub BUILD
{
  my $self = shift;

  if (defined $self->_config_handle)
  {
    my $handle = $self->_config_handle;
    my $content = do {local $/; <$handle>};

    if (length $content > 0)
    {
      $self->config( decode_json $content );
    }
  }

  return 1;
}

use overload 
  '@{}' => sub { shift->config },
  fallback => 1;

1;

__DATA__
[
  {
    "Name":   "Default Minimal",
    "Listen": "0.0.0.0:3001",
    "Protocol": "HTTP",
    "Handler": "Static",
    "Options":
    {
      "Path": "/docs/"
    }
  }
]
