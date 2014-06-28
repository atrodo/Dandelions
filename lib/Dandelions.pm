package Dandelions;

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
use Scalar::Util qw/blessed openhandle/;

use open qw/:encoding(UTF-8)/;

use Danga::Socket;

use Dandelions::Config;
use Dandelions::Server;

has config => (
  is      => 'rwp',
  default => sub
  {
    my $self = shift;
    return Dandelions::Config->new( $self->config_handle );
  },
  lazy => 1,
);

has config_handle => (
  is  => 'ro',
  isa => sub
  {
    my ($cfg) = @_;

    return
        if ref($cfg) eq "GLOB" && openhandle($cfg);

    return
        if blessed($cfg) && $cfg->isa("IO::Handle");

    croak "config_file does not appear to be a IO::Handle";
  },
  coerce => sub
  {
    my ($cfg) = @_;

    return $cfg
        if ref($cfg) eq "GLOB" && openhandle($cfg);

    return $cfg
        if blessed($cfg) && $cfg->isa("IO::Handle");

    # Do a tmpfile because in-memory string file won't truncate
    my $file = IO::File->new_tmpfile;

    $file->print($cfg);
    $file->seek( 0, 0 );
    return $file;
  },
  default => sub {""},
);

has servers => (
  is      => 'ro',
  coerce  => sub { [] },
  default => sub { [] },
);

has _child => (
  is => 'rw',
);

has _prepared => (
  is => 'rw',
);

sub load_new_config
{
  my $self   = shift;
  my $config = shift;

  my $config_handle = $self->config_handle;
  $config_handle->truncate(0);
  $config_handle->seek( 0, 0 );
  $config_handle->print($config);
  $config_handle->seek( 0, 0 );

  my $old_config = $self->config;

  try
  {
    $self->_set_config( Dandelions::Config->new( $self->config_handle ) );
  }
  catch
  {
    $self->_set_config($old_config);
    die "Cannot load new config: $_";
  };

  try
  {
    $self->_prepared(undef);
    $self->prepare;
  }
  catch
  {
    $self->_set_config($old_config);
    $self->_prepared(undef);
    $self->prepare;
    die "Cannot prepare new config: $_";
  };
}

sub prepare
{
  my $self = shift;

  return
      if $self->_prepared;

  my %current = map { $_->bound => $_->sock } @{ $self->servers };
  my @new_servers;

  foreach my $binding ( @{ $self->config } )
  {
    if ( defined $binding->{Listen} && exists $current{ $binding->{Listen} } )
    {
      $binding->{sock} = delete $current{ $binding->{Listen} };
    }

    push @new_servers,
        Dandelions::Server->new( %$binding, dandelion => $self );
  }

  @{ $self->servers } = (@new_servers);
  foreach my $server ( values %current )
  {
    $server->close;
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

  if ( $self->_child )
  {
    kill POSIX::SIGTERM, $self->_child;
  }
}

1;    # End of Dandelions

__END__

=encoding utf-8

=head1 NAME

Dandelions - PSGI based reverse proxy and webserver

=head1 SYNOPSIS

  use Dandelions;

=head1 DESCRIPTION

Dandelions is a PSGI based reverse proxy and webserver

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2012- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=cut
