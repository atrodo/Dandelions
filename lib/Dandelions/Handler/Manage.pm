package Dandelions::Handler::Manage;

use strict;
use warnings;

use Moo;
use Carp;

use autodie;
use JSON;
use Try::Tiny;
use Plack::Request;

my $json = JSON->new->relaxed(1);

with 'Dandelions::Handler';

has dandelion => (
  is => 'ro',
  required => 1,
  isa => sub
  {
    my ($dande) = @_;
    croak "$dande is not a Dandelions"
      unless $dande->isa("Dandelions");
  },
);

my $endpoints = {
  config => sub
  {
    my $self = shift;
    my $content = shift;
    $self->dandelion->load_new_config($content);
  },
};

sub process
{
  my $self = shift;
  my $env = shift;
  my $req = Plack::Request->new($env);

  return try
  {
  if ($req->path_info =~ m[^/api/v1 (/)? $ ]xms)
  {
    if (uc $req->method eq 'POST')
    {
      foreach my $key ( $req->parameters->keys )
      {
        foreach my $content ( $req->parameters->get_all($key) )
        {
          if(exists $endpoints->{$key})
          {
            $endpoints->{$key}->($self => $content);
            next;
          }
          die "Unknown Endpoint: $key";
        }
      }
    }
    return ['200', [ 'Content-Type' => 'text/plain' ], [ "Ok" ] ];
  }
  return ['404', [ 'Content-Type' => 'text/plain' ], [ "Not Found" ] ];
  }
  catch
  {
    warn $_;
    return ['500', [ 'Content-Type' => 'text/plain' ], [ "$_" ] ];
  };
}

1;

