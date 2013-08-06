package Stilts::Server;

use strict;
use warnings;

use Moo;
use Carp;

use Stilts::Socket;
use IO::Socket::INET;
use UNIVERSAL::require;

has name => (
  is       => 'rw',
  required => 1,
);

has bound => (
  is       => 'rw',
  required => 1,
);

has sock => (
  is       => 'rw',
  required => 1,
);

has protocol_class => (
  is       => 'ro',
  required => 1,
  coerce => sub
  {
    my $protocol_class  = join "::", "Stilts::Protocol", shift;

    croak $@
      if !$protocol_class->require;

    croak "$protocol_class does not implement Stilts::Protocol"
      unless $protocol_class->does("Stilts::Protocol");

    return $protocol_class;
  },
);

has handler_class => (
  is       => 'ro',
  required => 1,
  coerce => sub {
    my $handler_class  = join "::", "Stilts::Handler", shift;

    croak $@
      if !$handler_class->require;

    croak "$handler_class does not implement Stilts::Handler"
      unless $handler_class->does("Stilts::Handler");

    return $handler_class;
  },
);

has handler_options => (
  is       => 'ro',
  required => 1,
);

has handler => (
  is       => 'ro',
  required => 1,
  lazy => 1,
  builder => sub {
    my $self = shift;

    return $self->handler_class->new(
        {
          %{ $self->handler_options },
        }
      );
  },
);

has protocol => (
  is       => 'ro',
  required => 1,
  lazy => 1,
  builder => sub {
    my $self = shift;

    return $self->protocol_class->new( handler => $self->handler );
  },
);

around BUILDARGS => sub
{
  my $orig = shift;
  my $self = shift;

  my $args = $orig->( $self, @_ );

  $args->{name}     = delete $args->{Name};
  $args->{bound}    = delete $args->{Listen};
  $args->{protocol_class}  = delete $args->{Protocol};
  $args->{handler_class}  = delete $args->{Handler};
  $args->{handler_options}  = delete $args->{Options};

  $args->{sock} = Stilts::Socket->new(
    IO::Socket::INET->new(
      LocalAddr => $args->{bound},
      Proto     => "tcp",
      Listen    => 1024,
      ReuseAddr => 1,
    )
  );

  return $args;
};

sub BUILD
{
  my $self = shift;

  $self->sock->reader( $self );
}

sub reader
{
  my $self = shift;

  while ( my $psock = $self->sock->accept )
  {
    $psock->reader( $self->protocol->new_socket );
  }

  return 1;
}

1;
