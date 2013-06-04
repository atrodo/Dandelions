#!perl

use Test::More tests => 3;

use Stilts;
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

Stilts->new(config_handle => $cfg);

pass("Loaded a good JSON file");

is( try { Stilts->new(config_handle => "$cfg;"); 1; }, 1, "Did not load a bad JSON config");

$cfg =~ s/}/,}/g;
ok( Stilts->new(config_handle => "$cfg"), "Did load a hand crafted JSON config");
