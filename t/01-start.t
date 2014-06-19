#!/usr/bin/env perl

use Test::More tests => 1;

use Dandelions;

my $stilt = Dandelions->new();

$stilt->run_child;

pass("Started a background server");
