package Stilts;

use 5.008;
use strict;
use warnings;

use Moo;
use Sub::Quote;
use Carp;

use Danga::Socket;

use Stilts::Config;
use Stilts::Server;

has config => (
  is => 'ro',
  default => sub {
    my $self = shift;
    return Stilts::Config->new($self->config_file);
  },
  lazy => 1,
);

has config_file => (
  is => 'ro',
  isa => sub {
    warn Data::Dumper::Dumper(@_);
    return 1
      if !defined $_[0];
#    croak "config_file must be a File::Spec"
#      unless ref $_[0] eq "File::Spec";
    croak "config_file does not exist or cannot be read"
      unless -r $_[0];
  },
);

sub run
{
  my $self = shift;

  my $config = Stilts::Config->new($self->config_file);

  foreach my $binding (@{ $config->config })
  {
    Stilts::Server->new($binding);
  }

  Danga::Socket->EventLoop();
}

1; # End of Stilts
