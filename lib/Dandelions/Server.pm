package Dandelions::Server;

use strict;
use warnings;

use Moo;
use Carp;

use Dandelions::Socket;
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

has dandelion => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
  isa      => sub
  {
    my $dande = shift;
    croak "$dande is not an instance of Dandelions"
        unless $dande->isa("Dandelions");
  },
);

has protocol_class => (
  is       => 'ro',
  required => 1,
  coerce   => sub
  {
    my $protocol_class = join "::", "Dandelions::Protocol", shift;

    croak $@
        if !$protocol_class->require;

    croak "$protocol_class does not implement Dandelions::Protocol"
        unless $protocol_class->does("Dandelions::Protocol");

    return $protocol_class;
  },
);

has handler_class => (
  is       => 'ro',
  required => 1,
  coerce   => sub
  {
    my $handler_class = join "::", "Dandelions::Handler", shift;

    croak $@
        if !$handler_class->require;

    croak "$handler_class does not implement Dandelions::Handler"
        unless $handler_class->does("Dandelions::Handler");

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
  lazy     => 1,
  builder  => sub
  {
    my $self = shift;

    my $is_manager = $self->handler_class eq 'Dandelions::Handler::Manage';
    return $self->handler_class->new(
      {
        %{ $self->handler_options },
        ( $is_manager ? ( dandelion => $self->dandelion ) : () ),
      }
    );
  },
);

has protocol => (
  is       => 'ro',
  required => 1,
  lazy     => 1,
  builder  => sub
  {
    my $self = shift;

    return $self->protocol_class->new( handler => $self->handler );
  },
);

around BUILDARGS => sub
{
  my $orig = shift;
  my $self = shift;

  my $args = $orig->( $self, @_ );

  $args->{name}            = delete $args->{Name};
  $args->{bound}           = delete $args->{Listen};
  $args->{protocol_class}  = delete $args->{Protocol};
  $args->{handler_class}   = delete $args->{Handler};
  $args->{handler_options} = delete $args->{Options};

  if ( !defined $args->{sock} && defined $args->{bound} )
  {
    $args->{sock} = Dandelions::Socket->new(
      IO::Socket::INET->new(
        LocalAddr => $args->{bound},
        Proto     => "tcp",
        Listen    => 1024,
        ReuseAddr => 1,
      )
    );
  }

  return $args;
};

sub BUILD
{
  my $self = shift;

  $self->sock->reader($self);
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
