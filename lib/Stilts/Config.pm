package Stilts::Config;

use strict;
use warnings;

use Moo;
use Carp;
use JSON;
use autodie;

use Data::Dumper;

my $default_config = decode_json do { local $/; <DATA> };
close DATA;

has _config_file => (
  is => 'ro',
);

has config => (
  is => 'rw',
  default => sub { $default_config },
);

around BUILDARGS => sub
{
  my $orig = shift;
  my $self = shift;

  my $_config_file = ( defined $_[0] && -r $_[0] ) ? shift : undef;

  my $args = $orig->( $self, @_ );

  $args->{_config_file} = $_config_file;

  return $args;
};

sub BUILD
{
  my $self = shift;

  if (defined $self->_config_file)
  {
    open my $fh, "<", $self->_config_file;
    $self->config( decode_json do {local $/; <$fh>} );
    close $fh;
  }

  return 1;
}

1;

__DATA__
[
  {
    "Name":   "Default Minimal",
    "Listen": "0.0.0.0:3001",
    "Protocol": "HTTP",
    "Service": "Static",
    "Options":
    {
      "Path": "/docs/"
    }
  }
]
