#!perl

use Test::More tests => 1;

use Stilts;

my $stilt = Stilts->new();

$stilt->run_child;

ok("Started a background server");
