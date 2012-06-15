#!/usr/bin/env perl

use strict;
use warnings;

use Stilts;
use Getopt::Long qw//;
use File::Spec;
use FindBin;

my $opts = {};

my $parser = Getopt::Long::Parser->new();
$parser->configure( qw/auto_abbrev bundling auto_version auto_help/);
$parser->getoptions(
  $opts,
  'config|c=s',
  'help|h|?' => sub
  {
    require Pod::Usage;
    Pod::Usage::pod2usage(
      {
        -verbose => 1,
        -exitval => 0,
      }
    );
  },
  'man' => sub
  {
    require Pod::Usage;
    Pod::Usage::pod2usage(
      {
        -verbose => 2,
        -exitval => 0,
      }
    );
  },
);

if (!defined $opts->{config})
{
  my $default_config = "stilts.json";
  if (-r "$FindBin::Bin/$default_config")
  {
    $opts->{config} = "$FindBin::Bin/$default_config";
  }
  elsif (-r File::Spec->curdir() . "/$default_config")
  {
    $opts->{config} = File::Spec->curdir() . "/$default_config";
  }
}

#$opts->{config} = File::Spec->new($opts->{config})
#  if defined $opts->{config};

my $runner = Stilts->new(
  config_file => $opts->{config},
);

$runner->run;
