#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dandelions' ) || print "Bail out!\n";
}

diag( "Testing Dandelions $Dandelions::VERSION, Perl $], $^X" );
