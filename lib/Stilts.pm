package Stilts;

use 5.008;
use strict;
use warnings;

use Moo;
use Carp;

use Danga::Socket;

use Stilts::Config;
use Stilts::Server;

sub config
{
}

sub run
{
  my $self = shift;

  my $config = Stilts::Config->get_config;

  foreach my $binding (@$config)
  {
    Stilts::Server->new($binding);
  }

  Danga::Socket->EventLoop();
}

1; # End of Stilts
