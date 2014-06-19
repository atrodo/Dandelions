#!perl

use Test::More tests => 3;

use Dandelions;
use Try::Tiny;

my $port = "63021";
my $cfg = <<EOD;
[
  {
    "Listen": "127.0.0.1:$port",
    "Protocol": "PSGI",
    "Handler": "Static"
  }
]
EOD

Dandelions->new(config_handle => $cfg);

pass("Loaded a good JSON file");

is( try { Dandelions->new(config_handle => "$cfg;"); 1; }, 1, "Did not load a bad JSON config");

$cfg =~ s/}/,}/g;
ok( Dandelions->new(config_handle => "$cfg"), "Did load a hand crafted JSON config");
