package Stilts::Config;

use strict;
use warnings;

use Moo;
use Carp;
use JSON;

my $default_config = decode_json do { local $/; <DATA> };
close DATA;

sub get_config
{
  return $default_config;
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
