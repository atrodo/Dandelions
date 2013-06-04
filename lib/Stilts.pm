package Stilts;

our $VERSION = 0.1;

use 5.008;
use strict;
use warnings;

use Moo;
use Sub::Quote;
use Try::Tiny;

use Carp;
use autodie;
use IO::File;
use Scalar::Util qw/blessed/;

use open qw/:encoding(UTF-8)/;

use Danga::Socket;

use Stilts::Config;
use Stilts::Server;

has config => (
  is => 'ro',
  default => sub {
    my $self = shift;
    return Stilts::Config->new($self->config_handle);
  },
  lazy => 1,
);

has config_handle => (
  is => 'ro',
  isa => sub {
    my ($cfg) = @_;
    croak "config_file does not appear to be a IO::Handle"
      unless blessed($cfg) && $cfg->isa("IO::Handle");
  },
  coerce => sub {
    my ($cfg) = @_;
    return $cfg
      if blessed($cfg) && $cfg->isa("IO::Handle");

    try
    {
      # No need to check with autodie enabled; silently ignore errors
      return IO::File->new($cfg, "+<");
    };

    return IO::File->new(\$cfg, "+<");
  },
  default => sub { "" },
);

has _child => (
  is => 'rw',
);

has _prepared => (
  is => 'rw',
);

sub prepare
{
  my $self = shift;

  return
    if $self->_prepared;

  foreach my $binding (@{ $self->config })
  {
    Stilts::Server->new($binding);
  }

  $self->_prepared(1);
}

sub run
{
  my $self = shift;

  $self->prepare;

  Danga::Socket->EventLoop();
}

sub run_child
{
  my $self = shift;

  return $self->_child
    if defined $self->_child;

  # Check everything before forking
  $self->prepare;

  my $child = fork;

  if ($child)
  {
    my $rv = waitpid( $child, POSIX::WNOHANG );

    croak "Child process could not be forked: $?"
      if $rv < 0;

    $self->_child($child);
    return $child;
  }

  $self->run;
}

require POSIX;
sub DEMOLISH
{
  my $self = shift;

  if ($self->_child)
  {
    kill POSIX::SIGTERM, $self->_child;
  }
}

1; # End of Stilts

__END__

=encoding utf-8

=head1 NAME

Stilts - PSGI based reverse proxy and webserver

=head1 SYNOPSIS

  use Stilts;

=head1 DESCRIPTION

Stilts is a PSGI based reverse proxy and webserver

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2012- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=cut
