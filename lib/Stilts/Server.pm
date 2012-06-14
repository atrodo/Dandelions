package Stilts::Server;

use strict;
use warnings;

use Moo;
use Carp;

use Stilts::Socket;
use IO::Socket::INET;

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

has protocol => (
  is       => 'rw',
  required => 1,
);

has route => (
  is       => 'rw',
  required => 1,
);

around BUILDARGS => sub
{
  my $orig = shift;
  my $self = shift;

  my $args = $orig->( $self, @_ );

  $args->{name}     = delete $args->{Name};
  $args->{bound}    = delete $args->{Listen};
  $args->{protocol} = delete $args->{Protocol};
  $args->{route}    = delete $args->{Routing};

  my $server_class = "Stilts/Protocol/$args->{protocol}.pm";

  require $server_class;

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

  $self->{sock}->reader( \&reader, $self );
}

sub reader
{
  my $self = shift;

  while ( my $psock = $self->{sock}->accept )
  {
    my $protocol_class = "Stilts::Protocol::$self->{protocol}";

    $protocol_class->new(
      {
        sock   => $psock,
        route  => $self->route,
        server => $self,
      }
    );
  }

  return 1;
}

1;
