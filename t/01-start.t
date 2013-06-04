#!/usr/bin/env perl

use Test::More tests => 1;

use Stilts;

my $stilt = Stilts->new();

$stilt->run_child;

pass("Started a background server");
