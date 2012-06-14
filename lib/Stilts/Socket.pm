package Stilts::Socket;

use Moo;
use Carp;
use fields qw/reader_sub reader_self writer_sub writer_self/;

use Try::Tiny;

extends 'Danga::Socket';

has reader_sub => (
  is => 'rw',
  default => sub { sub {die "No reader defined"} },
);

has reader_self => (
  is => 'rw',
  default => sub { undef },
);

has writer_sub => (
  is => 'rw',
  default => sub { sub {die "No writer defined"} },
);

has writer_self => (
  is => 'rw',
  default => sub { undef },
);

sub BUILDARGS
{
  return {};
}

sub BUILD
{
  my $self = shift;

  $self->sock->blocking(0);
}

sub reader
{
  my $self = shift;
  my $sub = shift;
  my $alt_self = shift;

  croak "reader must be a coderef"
    unless !defined($sub) ||  $sub ne "CODE";

  $self->reader_sub($sub);
  $self->reader_self($alt_self);

  $self->watch_read(defined $sub);

  return;
}

sub writer
{
  my $self = shift;
  my $sub = shift;
  my $alt_self = shift;

  croak "writer must be a coderef"
    unless !defined($sub) ||  $sub ne "CODE";

  $self->writer_sub($sub);
  $self->writer_self($alt_self);

  return;
}

sub accept
{
  my $self = shift;

  my ($peersock, $peeraddr) = $self->sock->accept;

  return
    unless defined $peersock;

  $peersock->blocking(0);

  $peersock = __PACKAGE__->new($peersock);

  return wantarray ? ($peersock, $peeraddr) : $peersock;
}

sub event_read
{
  my $self = shift;

  try { $self->reader_sub->($self->reader_self || $self, @_); }
  catch {
    warn @_;
    $self->close;
  };
}

sub event_write
{
  my $self = shift;
  try { $self->writer_sub->($self, @_); }
  catch {
    warn @_;
    $self->close;
  };
}

#sub event_err {  my $self = shift; $self->close('error'); }
#sub event_hup {  my $self = shift; $self->close('hup'); }
#sub close { die }


1;
