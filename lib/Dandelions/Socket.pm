package Dandelions::Socket;

use Moo;
use Carp;
use Scalar::Util qw/blessed/;
use fields qw/reader_sub writer_sub/;

use Try::Tiny;

extends 'Danga::Socket';

has reader_sub => (
  is => 'rw',
  default => sub { sub {die "No reader defined"} },
  init_arg => 'reader',
);

has writer_sub => (
  is => 'rw',
  default => sub { sub { shift->write(undef); } },
  init_arg => 'writer',
);

sub BUILDARGS
{
  my $class = shift;
  my $socket = shift;

  return Moo::Object::BUILDARGS($class, @_);
};

sub BUILD
{
  my $self = shift;

  $self->sock->blocking(0);
  $self->watch_write(1);
}

BEGIN
{

  package MagicalCodeRef;

    require B;
  use overload '""' => sub
  {

    my $ref = shift;
    my $gv  = B::svref_2object($ref)->GV;
    sprintf "%s:%d", $gv->FILE, $gv->LINE;
  };

  sub enchant { bless $_[1], $_[0] }
}

sub reader
{
  my $self = shift;
  my $sub = shift;

  if (!defined $self)
  {
    $self->reader_sub(undef);
    $self->watch_read(0);
    return;
  }

  if ( blessed($sub) && $sub->can("reader") )
  {
    my $sub_self = $sub;
    $sub = sub {
      my $gv  = B::svref_2object($sub_self->can("reader"))->GV;
      warn sprintf "%s:%d\n", $gv->FILE, $gv->LINE;
      $sub_self->reader(@_);
    };
  }

  if ( ref $sub eq "CODE" )
  {
    my $sub_self = $sub;
    $sub = sub {
      my $gv  = B::svref_2object($sub_self)->GV;
      warn sprintf "%s:%d\n", $gv->FILE, $gv->LINE;
      $sub_self->(@_);
    };
  }

  croak "reader must be a coderef: $sub"
    unless ref $sub eq "CODE";


  $self->reader_sub($sub);

  $self->watch_read(1);

  return;
}

sub writer
{
  my $self = shift;
  my $sub = shift;

  if (!defined $self)
  {
    $self->writer_sub(undef);
    $self->watch_write(0);
    return;
  }

  if ( blessed($sub) && $sub->can("writer") )
  {
    my $sub_self = $sub;
    $sub = sub {
      $sub_self->writer(@_);
    };
  }

  croak "writer must be a coderef"
    unless ref $sub eq "CODE";

  $self->writer_sub($sub);

  $self->watch_write(1);

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

  warn $self . " " . $self->reader_sub . "\n";

  try { $self->reader_sub->($self, @_); }
  catch {
    warn "!!!: @_";
    $self->close;
  };

  #$self->close
  #  if !defined $self->read(0);
}

sub event_write
{
  my $self = shift;
  try {
    if ($self->writer_sub->($self, @_))
    {
      $self->watch_write(0);
    }
  }
  catch {
    warn @_;
    $self->close;
  };
}

sub event_err
{
  my $self = shift;

  $self->close;

  return 1;
}

#sub event_err {  my $self = shift; $self->close('error'); }
#sub event_hup {  my $self = shift; $self->close('hup'); }
#sub close { die }


1;
